import Foundation

struct PlantAISuggestion: Identifiable, Decodable {
    let id = UUID()
    let commonName: String
    let scientificName: String
    let otherName: String
    let fertilizingMonths: [Int]
    let pruningMonths: [Int]
    let wateringIntervals: PlantAIWateringIntervals
    let taxonomy: PlantAITaxonomy
    let careNotes: PlantAICareNotes
    let confidence: Double
    let caveat: String

    private enum CodingKeys: String, CodingKey {
        case commonName = "common_name"
        case scientificName = "scientific_name"
        case otherName = "other_name"
        case fertilizingMonths = "fertilizing_months"
        case pruningMonths = "pruning_months"
        case wateringIntervals = "watering_intervals"
        case taxonomy
        case careNotes = "care_notes"
        case confidence
        case caveat
    }
}

struct PlantAIWateringIntervals: Decodable {
    let spring: Int?
    let summer: Int?
    let fall: Int?
    let winter: Int?

    subscript(season: WateringSeason) -> Int? {
        switch season {
        case .spring: spring
        case .summer: summer
        case .fall: fall
        case .winter: winter
        }
    }

    var hasContent: Bool {
        WateringSeason.allCases.contains { self[$0] != nil }
    }
}

struct PlantAICareNotes: Decodable {
    let light: String
    let watering: String
    let soil: String
    let humidity: String
    let temperature: String
    let fertilizing: String
    let pruning: String
    let repotting: String
    let toxicity: String
    let warningSigns: String

    private enum CodingKeys: String, CodingKey {
        case light
        case watering
        case soil
        case humidity
        case temperature
        case fertilizing
        case pruning
        case repotting
        case toxicity
        case warningSigns = "warning_signs"
    }

    var hasContent: Bool {
        [
            light,
            watering,
            soil,
            humidity,
            temperature,
            fertilizing,
            pruning,
            repotting,
            toxicity,
            warningSigns
        ].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

struct WildFindAISuggestion: Identifiable, Decodable {
    let id = UUID()
    let scientificName: String
    let fieldGuide: WildFindAIFieldGuide
    let taxonomy: PlantAITaxonomy
    let confidence: Double
    let caveat: String

    private enum CodingKeys: String, CodingKey {
        case scientificName = "scientific_name"
        case fieldGuide = "field_guide"
        case taxonomy
        case confidence
        case caveat
    }
}

struct WildFindAIFieldGuide: Decodable {
    let appearance: String
    let identifyingFeatures: String
    let growthHabit: String
    let flowersAndFruit: String
    let habitat: String
    let nativeRange: String
    let lookalikes: String

    private enum CodingKeys: String, CodingKey {
        case appearance
        case identifyingFeatures = "identifying_features"
        case growthHabit = "growth_habit"
        case flowersAndFruit = "flowers_and_fruit"
        case habitat
        case nativeRange = "native_range"
        case lookalikes
    }

    var hasContent: Bool {
        [
            appearance,
            identifyingFeatures,
            growthHabit,
            flowersAndFruit,
            habitat,
            nativeRange,
            lookalikes
        ].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

struct PlantAITaxonomy: Decodable {
    let majorGroup: String
    let order: String
    let family: String
    let genus: String

    private enum CodingKeys: String, CodingKey {
        case majorGroup = "major_group"
        case order
        case family
        case genus
    }

    var hasContent: Bool {
        [majorGroup, order, family, genus]
            .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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
        guard await AIRegionalAvailability.isAvailableForCurrentStorefront() else {
            throw PlantAIServiceError.unavailableInRegion
        }

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
                throw PlantAIServiceError.api(
                    apiMessage ?? AppLocalization.string("OpenAI returned an error.")
                )
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
        guard await AIRegionalAvailability.isAvailableForCurrentStorefront() else {
            throw PlantAIServiceError.unavailableInRegion
        }

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
                throw PlantAIServiceError.api(
                    apiMessage ?? AppLocalization.string("OpenAI returned an error.")
                )
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
        let outputLanguage = localizedOutputLanguageInstruction
        let prompt = """
        The user entered the plant name “\(plantName)”.
        Existing species text, if any: “\(existingSpecies)”.
        The device region is “\(region)”.

        Suggest the most likely plant identity, beginner-friendly taxonomy, general fertilizing and pruning months, seasonal watering intervals, and practical care notes for ordinary home growing in that region. Month values must be integers from 1 through 12.

        For taxonomy, provide the broad major group in the requested output language, followed by the standard Latin order, family, and genus. The species is returned separately as the full standard Latin scientific name. Leave uncertain taxonomy fields empty rather than guessing.

        Suggest a watering interval in whole days from 1 through 90 for spring, summer, fall, and winter. Base the intervals on the plant's likely indoor needs, typical seasonal growth, and the user's region. Treat these as starting points that the user should adjust for light, temperature, humidity, pot size, and soil. Use null for every seasonal interval when the plant identity is too uncertain to make a responsible recommendation.

        Fill each care-notes field with one concise, plant-specific sentence, ideally under 20 words. Cover light, watering cues, soil, humidity, temperature, fertilizing, pruning, repotting, toxicity to people or pets, and visible warning signs. Keep the watering note focused on soil and plant cues rather than repeating the seasonal day intervals. Do not repeat the same advice across fields. Do not put labels, bullets, markdown, or line breaks inside field values because the app formats them. If a detail is not reliably known, say so briefly instead of inventing it.

        Common plant names can be ambiguous: if the identity is uncertain, leave uncertain identity, taxonomy, and care-note text empty, return empty month arrays, lower confidence, and explain what identifying details the user should verify. Do not present the result as guaranteed professional advice. \(outputLanguage)
        """

        return [
            "model": model,
            "store": false,
            "max_output_tokens": 950,
            "input": [
                [
                    "role": "developer",
                    "content": [[
                        "type": "input_text",
                        "text": "You are a practical, cautious horticultural assistant. Return only the requested structured plant identity, taxonomy, care calendar, seasonal watering intervals, and concise care notes."
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
                            "taxonomy": [
                                "type": "object",
                                "properties": [
                                    "major_group": ["type": "string"],
                                    "order": ["type": "string"],
                                    "family": ["type": "string"],
                                    "genus": ["type": "string"]
                                ],
                                "required": ["major_group", "order", "family", "genus"],
                                "additionalProperties": false
                            ],
                            "fertilizing_months": [
                                "type": "array",
                                "items": ["type": "integer", "minimum": 1, "maximum": 12]
                            ],
                            "pruning_months": [
                                "type": "array",
                                "items": ["type": "integer", "minimum": 1, "maximum": 12]
                            ],
                            "watering_intervals": [
                                "type": "object",
                                "properties": [
                                    "spring": ["type": ["integer", "null"], "minimum": 1, "maximum": 90],
                                    "summer": ["type": ["integer", "null"], "minimum": 1, "maximum": 90],
                                    "fall": ["type": ["integer", "null"], "minimum": 1, "maximum": 90],
                                    "winter": ["type": ["integer", "null"], "minimum": 1, "maximum": 90]
                                ],
                                "required": ["spring", "summer", "fall", "winter"],
                                "additionalProperties": false
                            ],
                            "care_notes": [
                                "type": "object",
                                "properties": [
                                    "light": ["type": "string"],
                                    "watering": ["type": "string"],
                                    "soil": ["type": "string"],
                                    "humidity": ["type": "string"],
                                    "temperature": ["type": "string"],
                                    "fertilizing": ["type": "string"],
                                    "pruning": ["type": "string"],
                                    "repotting": ["type": "string"],
                                    "toxicity": ["type": "string"],
                                    "warning_signs": ["type": "string"]
                                ],
                                "required": [
                                    "light",
                                    "watering",
                                    "soil",
                                    "humidity",
                                    "temperature",
                                    "fertilizing",
                                    "pruning",
                                    "repotting",
                                    "toxicity",
                                    "warning_signs"
                                ],
                                "additionalProperties": false
                            ],
                            "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                            "caveat": ["type": "string"]
                        ],
                        "required": [
                            "common_name",
                            "scientific_name",
                            "other_name",
                            "taxonomy",
                            "fertilizing_months",
                            "pruning_months",
                            "watering_intervals",
                            "care_notes",
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
        let outputLanguage = localizedOutputLanguageInstruction
        let prompt = """
        The user saved a wild plant under the name “\(plantName)”.
        Existing species text, if any: “\(existingSpecies)”.

        Suggest the most likely scientific species, a structured beginner-friendly field guide, and its taxonomy. Fill each field-guide value with one concise sentence, ideally under 20 words. Cover appearance, useful identifying features, growth habit, flowers or fruit, habitat, native range, and likely lookalikes. Do not repeat the same fact across fields, and leave a field empty when it is not reliably known.

        For taxonomy, provide the broad major group in the requested output language, followed by the standard Latin order, family, and genus. The species is returned separately as the full standard Latin scientific name. The user has not provided an image to analyze, so do not claim to have observed specific features in their individual plant. Do not include watering, fertilizing, pruning, propagation, or other care instructions. Do not put labels, bullets, markdown, or line breaks inside field values because the app formats them.

        Common names can be ambiguous: if identity is too uncertain, leave the scientific name and uncertain field values empty, lower confidence, and explain which visible features the user should verify. Do not present the result as a guaranteed identification. \(outputLanguage)
        """

        return [
            "model": model,
            "store": false,
            "max_output_tokens": 850,
            "input": [
                [
                    "role": "developer",
                    "content": [[
                        "type": "input_text",
                        "text": "You are a cautious botanical field-guide assistant. Return only the requested structured identification, field guide, and taxonomy, never a care guide."
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
                            "field_guide": [
                                "type": "object",
                                "properties": [
                                    "appearance": ["type": "string"],
                                    "identifying_features": ["type": "string"],
                                    "growth_habit": ["type": "string"],
                                    "flowers_and_fruit": ["type": "string"],
                                    "habitat": ["type": "string"],
                                    "native_range": ["type": "string"],
                                    "lookalikes": ["type": "string"]
                                ],
                                "required": [
                                    "appearance",
                                    "identifying_features",
                                    "growth_habit",
                                    "flowers_and_fruit",
                                    "habitat",
                                    "native_range",
                                    "lookalikes"
                                ],
                                "additionalProperties": false
                            ],
                            "taxonomy": [
                                "type": "object",
                                "properties": [
                                    "major_group": ["type": "string"],
                                    "order": ["type": "string"],
                                    "family": ["type": "string"],
                                    "genus": ["type": "string"]
                                ],
                                "required": ["major_group", "order", "family", "genus"],
                                "additionalProperties": false
                            ],
                            "confidence": ["type": "number", "minimum": 0, "maximum": 1],
                            "caveat": ["type": "string"]
                        ],
                        "required": [
                            "scientific_name",
                            "field_guide",
                            "taxonomy",
                            "confidence",
                            "caveat"
                        ],
                        "additionalProperties": false
                    ]
                ]
            ]
        ]
    }

    private var localizedOutputLanguageInstruction: String {
        switch AppLocalization.currentLanguage {
        case .simplifiedChinese:
            return "Write all user-facing text fields in Simplified Chinese. Keep scientific names in their standard Latin form."
        case .english:
            return "Write all user-facing text fields in English. Keep scientific names in their standard Latin form."
        }
    }
}

enum PlantAIServiceError: LocalizedError {
    case unavailableInRegion
    case invalidResponse
    case invalidAPIKey
    case rateLimited
    case api(String)
    case missingSuggestion
    case malformedSuggestion

    var errorDescription: String? {
        switch self {
        case .unavailableInRegion:
            return AppLocalization.string(
                "This feature is not available in your App Store region."
            )
        case .invalidResponse:
            return AppLocalization.string("PlantStory couldn’t read the OpenAI response.")
        case .invalidAPIKey:
            return AppLocalization.string("This API key was rejected. Check or replace it and try again.")
        case .rateLimited:
            return AppLocalization.string(
                "This OpenAI account is temporarily rate limited or needs billing credits."
            )
        case .api(let message):
            return message
        case .missingSuggestion, .malformedSuggestion:
            return AppLocalization.string(
                "OpenAI didn’t return a usable plant suggestion. Please try again."
            )
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
