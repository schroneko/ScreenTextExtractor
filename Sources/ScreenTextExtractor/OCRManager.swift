import Foundation
@preconcurrency import Vision
import CoreGraphics

@MainActor
class OCRManager {
    
    func extractText(from image: CGImage, completion: @escaping @Sendable (String) -> Void) {
        // 複数の設定でOCRを試行
        performOCRWithMultipleConfigurations(image: image, completion: completion)
    }
    
    private func performOCRWithMultipleConfigurations(image: CGImage, completion: @escaping @Sendable (String) -> Void) {
        // 設定1: 日本語優先
        let japaneseRequest = createJapaneseOptimizedRequest()
        
        // 設定2: 自動検出
        let autoRequest = createAutoDetectionRequest()
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        Task {
            var bestResult = ""
            var maxConfidence: Float = 0.0
            
            // 複数の設定を順次試行
            for (index, request) in [japaneseRequest, autoRequest].enumerated() {
                do {
                    try handler.perform([request])
                    
                    if let observations = request.results as [VNRecognizedTextObservation]? {
                        let (text, confidence) = processObservations(observations)
                        
                        print("OCR Configuration \(index + 1): '\(text)' (confidence: \(confidence))")
                        
                        if confidence > maxConfidence && !text.isEmpty {
                            bestResult = text
                            maxConfidence = confidence
                        }
                    }
                } catch {
                    print("OCR Configuration \(index + 1) failed: \(error)")
                }
            }
            
            print("Best OCR result: '\(bestResult)' (confidence: \(maxConfidence))")
            completion(bestResult)
        }
    }
    
    private func createJapaneseOptimizedRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        
        // 日本語特化設定
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja-JP"]
        request.automaticallyDetectsLanguage = false
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.01 // 小さな文字も認識
        
        if #available(macOS 13.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
        }
        
        return request
    }
    
    private func createAutoDetectionRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        
        // 自動検出設定
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja-JP", "en-US", "zh-CN", "ko-KR"]
        request.automaticallyDetectsLanguage = true
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.01
        
        if #available(macOS 13.0, *) {
            request.revision = VNRecognizeTextRequestRevision3
        }
        
        return request
    }
    
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> (text: String, confidence: Float) {
        var allTexts: [String] = []
        var totalConfidence: Float = 0.0
        var observationCount = 0
        
        for observation in observations {
            let candidates = observation.topCandidates(5) // より多くの候補を検討
            
            if let bestCandidate = candidates.first {
                allTexts.append(bestCandidate.string)
                totalConfidence += bestCandidate.confidence
                observationCount += 1
            }
        }
        
        let averageConfidence = observationCount > 0 ? totalConfidence / Float(observationCount) : 0.0
        let fullText = allTexts.joined(separator: "\n")
        
        return (fullText, averageConfidence)
    }
}