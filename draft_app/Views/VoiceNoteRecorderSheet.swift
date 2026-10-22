//
//  VoiceNoteRecorderSheet.swift
//  draft_app
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Voice Note Recorder & Voice Memos Integration

@Observable
final class AudioRecorderManager: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var isRecording = false
    var isPlaying = false
    var duration: TimeInterval = 0.0
    var audioData: Data? = nil
    var audioLevels: [Float] = [0.25, 0.4, 0.7, 0.5, 0.9, 0.6, 0.4, 0.8, 0.5, 0.35, 0.75, 0.6, 0.45, 0.55, 0.8, 0.4, 0.3, 0.65, 0.5, 0.3]
    var statusMessage: String? = nil
    
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var tempURL: URL?
    
    func checkPermissionAndStart() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self?.startRecording()
                    } else {
                        self?.statusMessage = "Microphone access denied. Enable it in Settings."
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self?.startRecording()
                    } else {
                        self?.statusMessage = "Microphone access denied. Enable it in Settings."
                    }
                }
            }
        }
    }
    
    func startRecording() {
        stopPlayback()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
        } catch {
            statusMessage = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        tempURL = url
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.isMeteringEnabled = true
            recorder?.record()
            
            isRecording = true
            duration = 0.0
            statusMessage = nil
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let rec = self.recorder, rec.isRecording else { return }
                rec.updateMeters()
                self.duration = rec.currentTime
                let power = rec.averagePower(forChannel: 0)
                let normalized = max(0.15, min(1.0, Float((power + 50) / 50)))
                self.audioLevels.removeFirst()
                self.audioLevels.append(normalized)
            }
        } catch {
            statusMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        isRecording = false
        
        if let url = tempURL, let data = try? Data(contentsOf: url) {
            audioData = data
            if duration < 1.0 { duration = 1.0 }
        }
    }
    
    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    func startPlayback() {
        guard let data = audioData else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            statusMessage = "Playback error: \(error.localizedDescription)"
        }
    }
    
    func stopPlayback() {
        player?.stop()
        isPlaying = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
    
    func loadAudioData(_ data: Data, fileName: String? = nil) {
        stopRecording()
        stopPlayback()
        audioData = data
        
        if let tempPlayer = try? AVAudioPlayer(data: data) {
            duration = max(1.0, tempPlayer.duration)
        } else {
            duration = 8.0
        }
        statusMessage = "Voice memo loaded (\(Int(duration))s)"
    }
    
    func cleanup() {
        stopRecording()
        stopPlayback()
    }
}

struct VoiceNoteRecorderSheet: View {
    let onSave: (Data?, Double, [Float]) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var manager = AudioRecorderManager()
    @State private var isShowingFileImporter = false
    @State private var pasteStatus: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Waveform & Time display
                VStack(spacing: 12) {
                    Text(formatTime(manager.duration))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(manager.isRecording ? .red : .primary)
                        .contentTransition(.numericText())
                    
                    HStack(spacing: 4) {
                        ForEach(0..<manager.audioLevels.count, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(manager.isRecording ? Color.red : SketchTheme.waveformPurple)
                                .frame(width: 5, height: CGFloat(max(8, manager.audioLevels[idx] * 48)))
                                .animation(.easeOut(duration: 0.1), value: manager.audioLevels[idx])
                        }
                    }
                    .frame(height: 52)
                    .padding(.horizontal)
                    
                    if let msg = manager.statusMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 16)
                
                // Record / Play Controls
                HStack(spacing: 36) {
                    if manager.audioData != nil && !manager.isRecording {
                        Button {
                            manager.togglePlayback()
                        } label: {
                            Image(systemName: manager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(SketchTheme.waveformPurple)
                        }
                    }
                    
                    Button {
                        if manager.isRecording {
                            manager.stopRecording()
                        } else {
                            manager.checkPermissionAndStart()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(manager.isRecording ? Color.red : Color.primary.opacity(0.2), lineWidth: 4)
                                .frame(width: 72, height: 72)
                            
                            if manager.isRecording {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.red)
                                    .frame(width: 28, height: 28)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 56, height: 56)
                            }
                        }
                    }
                    
                    if manager.audioData != nil && !manager.isRecording {
                        Button {
                            manager.cleanup()
                            manager.audioData = nil
                            manager.duration = 0
                            manager.statusMessage = nil
                            pasteStatus = nil
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal, 24)
                
                // Voice Memos App Integration Options
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            pasteFromClipboard()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("Paste from Clipboard")
                            }
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            isShowingFileImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                Text("Import Audio")
                            }
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if let status = pasteStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(status.contains("Copied") || status.contains("Loaded") ? .green : .secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    } else {
                        Text("To use Voice Memos: tap ••• on any recording, choose Copy, then tap Paste from Clipboard.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Voice Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        manager.cleanup()
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Card") {
                        manager.cleanup()
                        let finalDuration = max(1.0, manager.duration)
                        onSave(manager.audioData, finalDuration, manager.audioLevels)
                        dismiss()
                    }
                    .disabled(manager.audioData == nil && !manager.isRecording)
                    .fontWeight(.semibold)
                }
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: url) {
                            manager.loadAudioData(data, fileName: url.lastPathComponent)
                            pasteStatus = "Loaded file: \(url.lastPathComponent)"
                        }
                    }
                case .failure(let err):
                    manager.statusMessage = "Import failed: \(err.localizedDescription)"
                }
            }
            .onDisappear {
                manager.cleanup()
            }
        }
    }
    
    private func pasteFromClipboard() {
        let pasteboard = UIPasteboard.general
        
        let audioTypes = ["public.audio", "com.apple.m4a-audio", "public.mp3", "public.mpeg-4-audio", "com.apple.coreaudio-format"]
        for type in audioTypes {
            if let data = pasteboard.data(forPasteboardType: type) {
                manager.loadAudioData(data)
                pasteStatus = "Voice memo pasted successfully!"
                return
            }
        }
        
        if let url = pasteboard.url, ["m4a", "mp3", "wav", "aac"].contains(url.pathExtension.lowercased()) {
            if let data = try? Data(contentsOf: url) {
                manager.loadAudioData(data, fileName: url.lastPathComponent)
                pasteStatus = "Voice memo pasted from \(url.lastPathComponent)!"
                return
            }
        }
        
        pasteStatus = "No audio found on clipboard. Copy a recording from Voice Memos first."
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", mins, secs, tenths)
    }
}
