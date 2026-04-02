//
//  AnyPublisher+AsyncStream.swift
//  MuxPlayerSwift
//
//  Extracted from DownloadManager.swift
//

import Combine

extension AnyPublisher {
    func toAsyncThrowingStream() -> AsyncThrowingStream<Output, Failure> {
        AsyncThrowingStream { continuation in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                },
                receiveValue: { value in
                    continuation.yield(value)
                }
            )
            
            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }
}
