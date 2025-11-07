import Foundation

struct BenchmarkPrompt: Identifiable {
    let id: String
    let category: Category
    let text: String

    enum Category: String {
        case short
        case medium
        case long
    }
}

class BenchmarkPrompts {
    static let allPrompts: [BenchmarkPrompt] = [
        // Short prompts (5)
        BenchmarkPrompt(
            id: "short_1",
            category: .short,
            text: "Explain quantum computing in simple terms."
        ),
        BenchmarkPrompt(
            id: "short_2",
            category: .short,
            text: "Write a haiku about artificial intelligence."
        ),
        BenchmarkPrompt(
            id: "short_3",
            category: .short,
            text: "What are the benefits of exercise?"
        ),
        BenchmarkPrompt(
            id: "short_4",
            category: .short,
            text: "Describe the water cycle."
        ),
        BenchmarkPrompt(
            id: "short_5",
            category: .short,
            text: "List five programming languages and their uses."
        ),

        // Medium prompts (2)
        BenchmarkPrompt(
            id: "medium_1",
            category: .medium,
            text: """
                You are a helpful AI assistant. A user is building an iOS app that \
                performs inference with large language models on device. They want to \
                use Metal for GPU acceleration. Explain the key considerations for \
                optimizing Metal performance for LLM inference, including memory \
                management, compute shader design, and thermal throttling strategies.
                """
        ),
        BenchmarkPrompt(
            id: "medium_2",
            category: .medium,
            text: """
                Write a detailed comparison of three sorting algorithms: quicksort, \
                mergesort, and heapsort. Include time complexity, space complexity, \
                stability characteristics, and practical use cases. Then recommend \
                which algorithm would be best for sorting a large array of user records \
                by timestamp on a mobile device.
                """
        ),

        // Long prompt (1)
        BenchmarkPrompt(
            id: "long_1",
            category: .long,
            text: """
                You are an expert software architect designing a distributed system. \
                The system must handle real-time data processing for an IoT network \
                with millions of sensors. Requirements include:

                1. Ingest sensor data at 100,000 events per second
                2. Process data with <100ms latency for critical alerts
                3. Store historical data for 2 years with efficient querying
                4. Scale horizontally as sensor count grows
                5. Maintain 99.99% uptime
                6. Support both real-time dashboards and batch analytics
                7. Ensure data security and compliance with privacy regulations

                Design the system architecture, including:
                - Data ingestion layer (message queues, stream processing)
                - Processing pipeline (real-time vs batch)
                - Storage strategy (hot, warm, cold data tiers)
                - API layer for clients and dashboards
                - Monitoring and alerting infrastructure
                - Disaster recovery and backup strategies

                Justify your technology choices and explain the trade-offs. Consider \
                both cloud-native solutions and hybrid approaches.
                """
        ),
    ]

    static let shortPrompts = allPrompts.filter { $0.category == .short }
    static let mediumPrompts = allPrompts.filter { $0.category == .medium }
    static let longPrompts = allPrompts.filter { $0.category == .long }

    static func getPrompt(id: String) -> BenchmarkPrompt? {
        return allPrompts.first { $0.id == id }
    }

    static func getDefaultPromptForRunType(_ runType: RunType) -> BenchmarkPrompt {
        switch runType {
        case .sanity:
            return shortPrompts[0]
        case .full:
            return mediumPrompts[0]
        }
    }
}
