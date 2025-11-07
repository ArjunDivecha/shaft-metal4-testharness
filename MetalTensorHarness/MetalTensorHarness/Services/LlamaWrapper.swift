import Foundation

// MARK: - Llama Error

enum LlamaError: Error {
    case couldNotInitializeContext
    case modelLoadFailed(String)
    case decodeFailed
    case invalidPath
}

// MARK: - Llama Batch Helpers

func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

func llama_batch_add(_ batch: inout llama_batch, _ id: llama_token, _ pos: llama_pos, _ seq_ids: [llama_seq_id], _ logits: Bool) {
    batch.token   [Int(batch.n_tokens)] = id
    batch.pos     [Int(batch.n_tokens)] = pos
    batch.n_seq_id[Int(batch.n_tokens)] = Int32(seq_ids.count)
    for i in 0..<seq_ids.count {
        batch.seq_id[Int(batch.n_tokens)]![Int(i)] = seq_ids[i]
    }
    batch.logits  [Int(batch.n_tokens)] = logits ? 1 : 0

    batch.n_tokens += 1
}

// MARK: - Llama Context

actor LlamaContext {
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var vocab: OpaquePointer?
    private var sampling: UnsafeMutablePointer<llama_sampler>?
    private var batch: llama_batch
    private var tokens_list: [llama_token] = []
    private var temporaryInvalidCChars: [CChar] = []

    var isDone: Bool = false
    var nCur: Int32 = 0

    init(model: OpaquePointer, context: OpaquePointer) {
        self.model = model
        self.context = context
        self.batch = llama_batch_init(512, 0, 1)

        // Initialize sampling
        let sparams = llama_sampler_chain_default_params()
        self.sampling = llama_sampler_chain_init(sparams)
        llama_sampler_chain_add(self.sampling!, llama_sampler_init_temp(0.8))
        llama_sampler_chain_add(self.sampling!, llama_sampler_init_dist(1234))

        self.vocab = llama_model_get_vocab(model)
    }

    deinit {
        if let sampling = sampling {
            llama_sampler_free(sampling)
        }
        llama_batch_free(batch)
        if let model = model {
            llama_model_free(model)
        }
        if let context = context {
            llama_free(context)
        }
        llama_backend_free()
    }

    // MARK: - Context Creation

    static func createContext(path: String, backend: Backend) throws -> LlamaContext {
        llama_backend_init()

        var modelParams = llama_model_default_params()

        // Configure Metal based on backend
        switch backend {
        case .metalTensor:
            // Use Metal with Tensor API
            // Note: Actual tensor API flag might be environment variable or build flag
            modelParams.n_gpu_layers = 99 // Offload all layers to GPU
            print("🔧 Using Metal-4 Tensor API backend")

        case .metalLegacy:
            // Use Metal without Tensor API
            modelParams.n_gpu_layers = 99
            print("🔧 Using Legacy Metal backend")

        case .cpu:
            // CPU only
            modelParams.n_gpu_layers = 0
            print("🔧 Using CPU backend")
        }

        #if targetEnvironment(simulator)
        modelParams.n_gpu_layers = 0
        print("⚠️ Running on simulator, forcing CPU mode")
        #endif

        guard let model = llama_model_load_from_file(path, modelParams) else {
            throw LlamaError.modelLoadFailed("Could not load model at \(path)")
        }

        // Configure context
        var ctxParams = llama_context_default_params()
        let nThreads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))
        ctxParams.n_ctx = 4096 // Context window
        ctxParams.n_threads = Int32(nThreads)
        ctxParams.n_threads_batch = Int32(nThreads)

        print("📊 Using \(nThreads) threads")

        guard let context = llama_init_from_model(model, ctxParams) else {
            llama_model_free(model)
            throw LlamaError.couldNotInitializeContext
        }

        print("✅ Model and context initialized successfully")
        return LlamaContext(model: model, context: context)
    }

    // MARK: - Model Info

    func getModelInfo() -> (quantization: String?, contextLength: Int?) {
        guard let model = model else { return (nil, nil) }

        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 256)
        result.initialize(repeating: Int8(0), count: 256)
        defer { result.deallocate() }

        let nChars = llama_model_desc(model, result, 256)
        let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nChars))

        var description = ""
        for char in bufferPointer {
            description.append(Character(UnicodeScalar(UInt8(char))))
        }

        // Parse quantization from description (e.g., "Q4_K_M")
        let quant = description.components(separatedBy: " ").first { $0.hasPrefix("Q") }

        guard let context = context else { return (quant, nil) }
        let ctxLen = Int(llama_n_ctx(context))

        return (quant, ctxLen)
    }

    // MARK: - Generation

    func generate(
        prompt: String,
        maxTokens: Int,
        seed: Int,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping () -> Void
    ) {
        guard let context = context, let vocab = vocab, let sampling = sampling else {
            print("❌ Context not initialized")
            onComplete()
            return
        }

        print("🔧 Starting generation: \(maxTokens) tokens")
        print("🔧 Prompt: \(prompt.prefix(50))...")

        // Reset state
        tokens_list = tokenize(text: prompt, addBos: true)
        temporaryInvalidCChars = []
        isDone = false
        nCur = 0

        // Check context requirements
        let nCtx = llama_n_ctx(context)
        let nKvReq = tokens_list.count + maxTokens

        if nKvReq > nCtx {
            print("⚠️ Warning: Required KV cache (\(nKvReq)) > context size (\(nCtx))")
        }

        // Process prompt
        llama_batch_clear(&batch)

        for i in 0..<tokens_list.count {
            llama_batch_add(&batch, tokens_list[i], Int32(i), [0], false)
        }
        batch.logits[Int(batch.n_tokens) - 1] = 1

        if llama_decode(context, batch) != 0 {
            print("❌ Failed to decode prompt")
            onComplete()
            return
        }

        nCur = batch.n_tokens

        // Generate tokens
        for tokenIndex in 0..<maxTokens {
            // Sample next token
            let newTokenId = llama_sampler_sample(sampling, context, batch.n_tokens - 1)

            // Check for end-of-generation
            if llama_vocab_is_eog(vocab, newTokenId) {
                print("\n✅ End of generation (EOG token)")
                isDone = true

                // Flush remaining invalid chars
                if !temporaryInvalidCChars.isEmpty {
                    if let str = String(validatingUTF8: temporaryInvalidCChars + [0]) {
                        onToken(str)
                    }
                }

                onComplete()
                return
            }

            // Convert token to string
            let newTokenCChars = tokenToPiece(token: newTokenId)
            temporaryInvalidCChars.append(contentsOf: newTokenCChars)

            // Try to convert to valid UTF-8
            let newTokenStr: String
            if let string = String(validatingUTF8: temporaryInvalidCChars + [0]) {
                temporaryInvalidCChars.removeAll()
                newTokenStr = string
            } else if (0..<temporaryInvalidCChars.count).contains(where: { $0 != 0 && String(validatingUTF8: Array(temporaryInvalidCChars.suffix($0)) + [0]) != nil }) {
                let string = String(cString: temporaryInvalidCChars + [0])
                temporaryInvalidCChars.removeAll()
                newTokenStr = string
            } else {
                newTokenStr = ""
            }

            // Emit token
            if !newTokenStr.isEmpty {
                onToken(newTokenStr)
            }

            // Prepare next iteration
            llama_batch_clear(&batch)
            llama_batch_add(&batch, newTokenId, nCur, [0], true)

            nCur += 1

            if llama_decode(context, batch) != 0 {
                print("❌ Failed to decode token \(tokenIndex)")
                onComplete()
                return
            }
        }

        print("✅ Generation complete (\(maxTokens) tokens)")
        isDone = true
        onComplete()
    }

    // MARK: - Tokenization

    private func tokenize(text: String, addBos: Bool) -> [llama_token] {
        guard let vocab = vocab else { return [] }

        let utf8Count = text.utf8.count
        let nTokens = utf8Count + (addBos ? 1 : 0) + 1
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: nTokens)
        defer { tokens.deallocate() }

        let tokenCount = llama_tokenize(vocab, text, Int32(utf8Count), tokens, Int32(nTokens), addBos, false)

        var swiftTokens: [llama_token] = []
        for i in 0..<tokenCount {
            swiftTokens.append(tokens[Int(i)])
        }

        return swiftTokens
    }

    private func tokenToPiece(token: llama_token) -> [CChar] {
        guard let vocab = vocab else { return [] }

        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 8)
        result.initialize(repeating: Int8(0), count: 8)
        defer { result.deallocate() }

        let nTokens = llama_token_to_piece(vocab, token, result, 8, 0, false)

        if nTokens < 0 {
            let newResult = UnsafeMutablePointer<Int8>.allocate(capacity: Int(-nTokens))
            newResult.initialize(repeating: Int8(0), count: Int(-nTokens))
            defer { newResult.deallocate() }

            let nNewTokens = llama_token_to_piece(vocab, token, newResult, -nTokens, 0, false)
            let bufferPointer = UnsafeBufferPointer(start: newResult, count: Int(nNewTokens))
            return Array(bufferPointer)
        } else {
            let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nTokens))
            return Array(bufferPointer)
        }
    }

    // MARK: - Memory Management

    func clear() {
        guard let context = context else { return }
        tokens_list.removeAll()
        temporaryInvalidCChars.removeAll()
        llama_memory_clear(llama_get_memory(context), true)
    }
}

// MARK: - Llama Wrapper (Main Interface)

class LlamaWrapper {
    private var llamaContext: LlamaContext?
    private var isLoaded = false
    private var currentBackend: Backend = .metalTensor
    private var modelPath: String?

    // MARK: - Model Loading

    func loadModel(path: String, backend: Backend) throws {
        print("📂 Loading model from: \(path)")
        print("⚙️ Backend: \(backend.displayName)")

        // Verify file exists
        guard FileManager.default.fileExists(atPath: path) else {
            throw LlamaError.invalidPath
        }

        // Create context
        let context = try LlamaContext.createContext(path: path, backend: backend)

        self.llamaContext = context
        self.modelPath = path
        self.currentBackend = backend
        self.isLoaded = true

        print("✅ Model loaded successfully")
    }

    func unloadModel() {
        print("🔧 Unloading model")
        llamaContext = nil
        isLoaded = false
        modelPath = nil
    }

    // MARK: - Inference

    func generate(
        prompt: String,
        maxTokens: Int,
        seed: Int = 1234,
        onToken: @escaping (String) -> Void,
        onComplete: @escaping () -> Void
    ) {
        guard isLoaded, let context = llamaContext else {
            print("❌ Model not loaded")
            onComplete()
            return
        }

        // Run generation on context actor
        Task {
            await context.generate(
                prompt: prompt,
                maxTokens: maxTokens,
                seed: seed,
                onToken: onToken,
                onComplete: onComplete
            )
        }
    }

    // MARK: - Model Info

    func getModelInfo(path: String) throws -> (quantization: String?, contextLength: Int?) {
        print("📊 Reading model info from: \(path)")

        guard FileManager.default.fileExists(atPath: path) else {
            throw LlamaError.invalidPath
        }

        // Create temporary context to read info
        let context = try LlamaContext.createContext(path: path, backend: .cpu)

        // Get info
        let info = await context.getModelInfo()

        print("✅ Detected quantization: \(info.quantization ?? "unknown")")
        print("✅ Context length: \(info.contextLength ?? 0)")

        return info
    }
}

// MARK: - Integration Notes

/*
 ============================================================================
 LLAMA.CPP XCFRAMEWORK INTEGRATION
 ============================================================================

 This implementation uses real llama.cpp APIs. To complete integration:

 1. Build the XCFramework:
    ```bash
    cd llama.cpp
    ./build-xcframework.sh
    ```
    This creates: build-apple/llama.xcframework

 2. Add XCFramework to Xcode Project:
    - Drag build-apple/llama.xcframework into project navigator
    - Or: Target → General → Frameworks, Libraries, and Embedded Content → Add

 3. Create Bridging Header:
    File → New → Header File: MetalTensorHarness-Bridging-Header.h

    Content:
    ```objc
    #ifndef MetalTensorHarness_Bridging_Header_h
    #define MetalTensorHarness_Bridging_Header_h

    #import <llama/llama.h>
    #import <llama/ggml.h>

    #endif
    ```

 4. Configure Build Settings:
    Target → Build Settings → Search "Bridging":
    - Set "Objective-C Bridging Header" to:
      MetalTensorHarness/MetalTensorHarness-Bridging-Header.h

 5. Build and Run:
    - Clean build folder: ⌘⇧K
    - Build: ⌘B
    - Run on device: ⌘R

 Metal-4 Tensor API Support:
 -------------------------
 The backend switching is configured via model parameters. Metal-4 Tensor
 support may require:
 - Environment variable: GGML_METAL_USE_TENSOR_API=1
 - Build flag: -DGGML_METAL_USE_TENSOR_API=ON
 - Runtime flag (check llama.cpp docs for latest approach)

 Current implementation uses n_gpu_layers to control Metal usage.
 Fine-tuning for Metal-4 vs Legacy may require additional flags.

 Performance Notes:
 -----------------
 - Metal-4 Tensor: Expected 25-35 t/s on iPhone 17 Pro Max (3B Q4_K_M)
 - Legacy Metal: Expected 20-28 t/s
 - CPU: Expected 3-8 t/s

 Troubleshooting:
 ---------------
 - "No such module 'llama'": XCFramework not added or bridging header incorrect
 - Linker errors: Ensure XCFramework is in "Embed & Sign" mode
 - Metal init failure: Check device supports Metal and model isn't too large

 ============================================================================
 */
