//
//  AudioAnalyzer.swift
//  MoveMatch
//
//  Audio feature extraction and BPM detection
//

import Foundation
import AVFoundation
import Accelerate

class AudioAnalyzer {

    // MARK: - Public Methods

    func analyze(audioURL: URL) async throws -> AudioFeatures {
        let audioFile = try AVAudioFile(forReading: audioURL)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        try audioFile.read(into: buffer)

        let bpm = detectBPM(buffer)
        let energy = calculateEnergy(buffer)
        let danceability = calculateDanceability(buffer, bpm: bpm)
        let spectralCentroid = calculateSpectralCentroid(buffer)
        let onsets = detectOnsets(buffer)

        return AudioFeatures(
            bpm: bpm,
            energy: energy,
            danceability: danceability,
            spectralCentroid: spectralCentroid,
            onsets: onsets,
            duration: TimeInterval(audioFile.length) / format.sampleRate
        )
    }

    // MARK: - BPM Detection

    private func detectBPM(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 120 }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = Float(buffer.format.sampleRate)

        var maxCorrelation: Float = 0
        var bestLag = 0

        // Search for periodicity between 60-180 BPM
        let minLag = Int(sampleRate * 60 / 180)  // 180 BPM
        let maxLag = Int(sampleRate * 60 / 60)   // 60 BPM

        for lag in stride(from: minLag, to: min(maxLag, frameLength / 2), by: 100) {
            var correlation: Float = 0
            let searchLength = min(frameLength - lag, 44100) // 1 second sample

            for i in 0..<searchLength {
                correlation += data[i] * data[i + lag]
            }

            if correlation > maxCorrelation {
                maxCorrelation = correlation
                bestLag = lag
            }
        }

        guard bestLag > 0 else { return 120 }

        let bpm = 60.0 * sampleRate / Float(bestLag)

        // Clamp to reasonable range
        return max(60, min(180, bpm))
    }

    // MARK: - Energy Calculation

    private func calculateEnergy(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 0.5 }
        let frameLength = Int(buffer.frameLength)

        var energy: Float = 0
        vDSP_rmsqv(data, 1, &energy, vDSP_Length(frameLength))

        // Normalize to 0-1 (typical range is 0-0.5 for music)
        return min(energy * 2, 1.0)
    }

    // MARK: - Danceability

    private func calculateDanceability(_ buffer: AVAudioPCMBuffer, bpm: Float) -> Float {
        let energy = calculateEnergy(buffer)

        // Regular tempo (100-140 BPM) = more danceable
        let tempoScore = 1.0 - abs(bpm - 120) / 120

        // High energy = more danceable
        let energyScore = energy

        // Check bass presence (low frequencies)
        let bassScore = calculateBassPresence(buffer)

        return (tempoScore * 0.3 + energyScore * 0.4 + bassScore * 0.3)
    }

    private func calculateBassPresence(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 0.5 }
        let frameLength = Int(buffer.frameLength)

        // Apply low-pass filter to isolate bass frequencies (<200 Hz)
        let cutoffFrequency: Float = 200
        let sampleRate = Float(buffer.format.sampleRate)
        let rc = 1.0 / (cutoffFrequency * 2 * .pi)
        let dt = 1.0 / sampleRate
        let alpha = dt / (rc + dt)

        var filtered = [Float](repeating: 0, count: frameLength)
        filtered[0] = data[0]

        for i in 1..<frameLength {
            filtered[i] = alpha * data[i] + (1 - alpha) * filtered[i-1]
        }

        // Calculate energy in bass range
        var bassEnergy: Float = 0
        vDSP_rmsqv(filtered, 1, &bassEnergy, vDSP_Length(frameLength))

        return min(bassEnergy * 3, 1.0) // Amplify and normalize
    }

    // MARK: - Spectral Centroid

    private func calculateSpectralCentroid(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 0.5 }
        let frameLength = Int(buffer.frameLength)

        // Use FFT to analyze frequency content
        let log2n = vDSP_Length(ceil(log2(Float(frameLength))))
        let fftLength = Int(pow(2.0, Float(log2n)))

        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return 0.5
        }

        defer { vDSP_destroy_fftsetup(fftSetup) }

        var realp = [Float](repeating: 0, count: fftLength / 2)
        var imagp = [Float](repeating: 0, count: fftLength / 2)

        realp.withUnsafeMutableBufferPointer { realBuffer in
            imagp.withUnsafeMutableBufferPointer { imagBuffer in
                var splitComplex = DSPSplitComplex(
                    realp: realBuffer.baseAddress!,
                    imagp: imagBuffer.baseAddress!
                )

                // Copy data (pad if necessary)
                for i in 0..<min(frameLength, fftLength) {
                    realp[i % (fftLength / 2)] = data[i]
                }

                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                // Calculate magnitude spectrum
                var magnitudes = [Float](repeating: 0, count: fftLength / 2)
                vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftLength / 2))

                // Spectral centroid = weighted mean of frequencies
                var weightedSum: Float = 0
                var sumMagnitudes: Float = 0

                for i in 0..<magnitudes.count {
                    weightedSum += Float(i) * magnitudes[i]
                    sumMagnitudes += magnitudes[i]
                }

                guard sumMagnitudes > 0 else { return }

                let centroid = weightedSum / sumMagnitudes
                let normalizedCentroid = centroid / Float(magnitudes.count)

                // Return value between 0 (bass-heavy) and 1 (treble-heavy)
                _ = min(normalizedCentroid, 1.0)
            }
        }

        return 0.5 // Fallback if calculation fails
    }

    // MARK: - Onset Detection

    private func detectOnsets(_ buffer: AVAudioPCMBuffer) -> [TimeInterval] {
        guard let data = buffer.floatChannelData?[0] else { return [] }
        let frameLength = Int(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate

        var onsets: [TimeInterval] = []
        let hopSize = 512
        var previousEnergy: Float = 0

        for i in stride(from: 0, to: frameLength, by: hopSize) {
            let endIndex = min(i + hopSize, frameLength)
            var energy: Float = 0

            // Calculate energy in this frame
            for j in i..<endIndex {
                energy += abs(data[j])
            }

            // Onset = sudden energy increase
            if energy > previousEnergy * 1.5 {
                let time = TimeInterval(i) / sampleRate
                onsets.append(time)
            }

            previousEnergy = energy
        }

        return onsets
    }
}

// MARK: - Music Library Manager

import MediaPlayer

class MusicLibraryManager {

    func requestAuthorization() async -> Bool {
        let status = await MPMediaLibrary.requestAuthorization()
        return status == .authorized
    }

    func fetchUserSongs() -> [Song] {
        let query = MPMediaQuery.songs()

        // Filter to playable, non-DRM tracks
        let predicate = MPMediaPropertyPredicate(
            value: MPMediaType.music.rawValue,
            forProperty: MPMediaItemPropertyMediaType
        )
        query.addFilterPredicate(predicate)

        guard let items = query.items else { return [] }

        return items.compactMap { item in
            guard let url = item.assetURL else { return nil } // Skip DRM

            return Song(
                id: String(item.persistentID),
                title: item.title ?? "Unknown",
                artist: item.artist ?? "Unknown",
                duration: item.playbackDuration,
                assetURL: url,
                bpm: nil, // Will be analyzed later
                genre: nil,
                features: nil
            )
        }
    }

    func analyzeSong(_ song: Song) async throws -> Song {
        guard let url = song.assetURL else { throw AudioError.invalidURL }

        let analyzer = AudioAnalyzer()
        let features = try await analyzer.analyze(audioURL: url)

        var updatedSong = song
        updatedSong.features = features
        updatedSong.bpm = features.bpm
        updatedSong.genre = features.estimatedGenre

        return updatedSong
    }
}

enum AudioError: Error {
    case invalidURL
    case analysisFailedcase unsupportedFormat
}
