import Foundation

struct PlantAISuggestion: Identifiable, Decodable {
    let id = UUID()
    let commonName: String
    let scientificName: String
    let otherName: String
    let fertilizingMonths: [Int]
    let pruningMonths: [Int]
    let careSummary: String
    let confidence: Double
    let caveat: String

    private enum CodingKeys: String, CodingKey {
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case otherName = "other_name"
        case fertilizingMonths = "fertilizing_months"
        case pruningMonths = "pruning_months"
        case careSummary = "care_summary"
        case confidence
        case caveat
    }
}

struct WildFindAISuggestion: Identifiable, Decodable {
    let id = UUID()
    let scientificName: String
    let description: String
    let confidence: Double
    let caveat: String

    private enum CodingKeys: String, CodingKey {
        case scientificName = "scientific_name"
        case description
        case confidence
        case caveat
    }
}

actor PlantAIService {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private let model = "gpt-5.4-nano"

    func suggestDetails(
        plantName: String,
        existingSpecies: String,
        apiKey: String
    ) async throws -> PlantAISuggestion {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody(
            plantName: plantName,
            existingSpecies: existingSpecies
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlantAIServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiMessage = (try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data))?.error.message
            switch httpResponse.statusCode {
            case 401:
                throw PlantAIServiceError.invalidAPIKey
            case 429:
                throw PlantAIServiceError.rateLimited
            default:
                throw PlantAIServiceError.api(apiMessage ?? "OpenAI returned an error.")
            }
        }

        let responseBody = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let responseContent = responseBody.output.flatMap { $0.content ?? [] }
        guard let outputText = responseContent
            .first(where: { $0.type == "output_text" })?
            .text,
              let suggestionData = outputText.data(using: .utf8) else {
            throw PlantAIServiceError.missingSuggestion
        }

        do {
            return try JSONDecoder().decode(PlantAISuggestion.self, from: suggestionData)
        } catch {
            throw PlantAIServiceError.malformedSuggestion
        }
    }

    func suggestWildFindDetails(
        plantName: String,
        existingSpecies: String,
        apiKey: String
    ) async throws -> WildFindAISuggestion {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONSerialization.data(withJSONObject: wildFindRequestBody(
            plantName: plantName,
            existingSpecies: existingSpecies
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PlantAIServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let apiMessage = (try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data))?.error.message
            switch httpResponse.statusCode {
            case 401:
                throw PlantAIServiceError.invalidAPIKey
            case 429:
                throw PlantAIServiceError.rateLimited
            default:
                throw PlantAIServiceError.api(apiMessage ?? "OpenAI returned an error.")
            }
        }

        let responseBody = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let responseContent = responseBody.output.flatMap { $0.content ?? [] }
        guard let outputText = responseContent
            .first(where: { $0.type == "output_text" })?
            .text,
              let suggestionData = outputText.data(using: .utf8) else {
            throw PlantAIServiceError.missingSuggestion
        }

        do {
            return try JSONDecoder().decode(WildFindAISuggestion.self, from: suggestionData)
        } catch {
            throw PlantAIServiceError.malformedSuggestion
        }
    }

    private func requestBody(plantName: String, existingSpecies: String) -> [String: Any] {
        let region = Locale.current.region?.identifier ?? Locale.current.identifier
        let prompt = """
        The user entered the plant name “\(plantName)”.
        Existing species text, if any: “\(existingSpecies)”.
        The device region is “\(region)”.

        Suggest the most likely plant identity and general fertilizing and pruning months for ordinary home growing in that region. Month values must be integers from 1 through 12. Common plant names can be ambiguous: if the identity is uncertain, leave uncertain text empty, return empty month arrays, lower confidence, and explain what the user should verify. Keep the care summary to two short sentences. Do not present the result as guaranteed professional advice.
        """

        return [
            "model": model,
            "store": false,
            "max_output_tokens": 800,
            "input": [
                [
                    "role": "developer",
                    "content": [[
                        "type": "input_text",
                        "text": "You are a cautious horticultural assistant. Return only the requested structured plant-care suggestion."
                    ]]
                ],
                [
                    "role": "user",
                    "content": [[
                        "type": "input_text",
                        "text": prompt
                    ]]
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "plant_care_suggestion",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "properties": [
                            "common_name": ["type": "string"],
                            "scientific_name": ["type": "string"],
                            "other_name": ["type": "string"],
                            "fertilizing_months": [
                                "type": "array",
                                "items": ["type": "integer", "minimum": 1, "maximum": 12]
                            ],
                            "pruning_months": [
                                "type": "array",
                                "items": ["type": "integer", "minimum": 1, "maximum": 12]
                            ],
                            "care_summary": ["type": "string"],
                            "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                            "caveat": ["type": "string"]
                        ],
                        "required": [
                            "common_name",
                            "scientific_name",
                            "other_name",
                            "fertilizing_months",
                            "pruning_months",
                            "care_summary",
                            "confidence",
                            "caveat"
                        ],
                        "additionalProperties": false
                    ]
                ]
            ]
        ]
    }

    private func wildFindRequestBody(plantName: String, existingSpecies: String) -> [String: Any] {
        let prompt = """
        The user saved a wild plant under the name “\(plantName)”.
        Existing species text, if any: “\(existingSpecies)”.

        Suggest the most likely scientific species and a concise field-guide description. The description should be two to four short sentences focused on the likely plant’s appearance, notable botanical traits, and typical habitat or native range when reliable. The user has not provided an image to analyze, so do not claim to have observed specific features in their individual plant. Do not include watering, fertilizing, pruning, propagation, or other care instructions. Common names can be ambiguous: if identity is uncertain, leave the scientific name empty, lower confidence, and explain what identifying details the user should verify.
        """

        return [
            "model": model,
            "store": false,
            "max_output_tokens": 600,
            "input": [
                [
                    "role": "developer",
                    "content": [[
                        "type": "input_text",
                        "text": "You are a cautious botanical field-guide assistant. Return only the requested structured identification and plant description, never a care guide."
                    ]]
                ],
                [
                    "role": "user",
                    "content": [[
                        "type": "input_text",
                        "text": prompt
                    ]]
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "wild_find_suggestion",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "properties": [
                            "scientific_name": ["type": "string"],
                            "description": ["type": "string"],
                            "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                            "caveat": ["type": "string"]
                        ],
                        "required": [
                            "scientific_name",
                            "description",
                            "confidence",
                            "caveat"
                        ],
                        "additionalProperties": false
                    ]
                ]
            ]
        ]
    }
}

enum PlantAIServiceError: LocalizedError {
    case invalidResponse
    case invalidAPIKey
    case rateLimited
    case api(String)
    case missingSuggestion
    case malformedSuggestion

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "PlantStory couldn’t read the OpenAI response."
        case .invalidAPIKey:
            return "This API key was rejected. Check or replace it and try again."
        case .rateLimited:
            return "This OpenAI account is temporarily rate limited or needs billing credits."
        case .api(let message):
            return message
        case .missingSuggestion, .malformedSuggestion:
            return "OpenAI didn’t return a usable plant suggestion. Please try again."
        }
    }
}

private struct OpenAIResponse: Decodable {
    let output: [Output]

    struct Output: Decodable {
        let content: [Content]?
    }

    struct Content: Decodable {
        let type: String
        let text: String?
    }
}

private struct OpenAIErrorEnvelope: Decodable {
    let error: APIError

    struct APIError: Decodable {
        let message: String
    }
}
