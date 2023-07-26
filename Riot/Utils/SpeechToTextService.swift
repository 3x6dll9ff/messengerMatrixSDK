// swiftlint:disable all

import Foundation

class SpeechToTextService {
    private let apiKey: String
    private let urlSession = URLSession.shared

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func transcribeAudio(audioFileURL: URL, completion: @escaping (String?, Error?) -> Void) {
        let url = URL(string: "https://speech.googleapis.com/v1/speech:recognize?key=\(apiKey)")!

        guard let audioBase64 = encodeAudioFileToBase64(audioFileURL: audioFileURL) else {
            completion(nil, NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode audio file"]))
            return
        }

        let jsonRequest: [String: Any] = [
            "config": [
                "encoding": "OGG_OPUS",
                "sampleRateHertz": 48000,
                "languageCode": "ru-RU"
            ],
            "audio": [
                "content": audioBase64
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonRequest, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
            } else if let data = data {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])
                    }
                    
                    print("Server response: \(String(data: data, encoding: .utf8) ?? "No data")") // Add this line

                    let placeholderTranscription = "Не удалось распознать речь"
                    let transcription = self.extractTranscription(json: json) ?? placeholderTranscription
                    completion(transcription, nil)
                } catch {
                    completion(nil, error)
                }
            }
        }.resume()
    }

    private func encodeAudioFileToBase64(audioFileURL: URL) -> String? {
        print(audioFileURL)
        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            return nil
        }

        return audioData.base64EncodedString()
    }

    private func extractTranscription(json: [String: Any]) -> String? {
        guard let results = json["results"] as? [[String: Any]], let firstResult = results.first,
              let alternatives = firstResult["alternatives"] as? [[String: Any]], let firstAlternative = alternatives.first,
              let transcript = firstAlternative["transcript"] as? String else {
            return nil
        }

        return transcript
    }
}
