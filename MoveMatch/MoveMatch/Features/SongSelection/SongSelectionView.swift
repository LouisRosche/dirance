//
//  SongSelectionView.swift
//  MoveMatch
//
//  Browse and select songs from library
//

import SwiftUI

struct SongSelectionView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""
    @State private var selectedSong: Song?
    @State private var showingGameplay = false
    @State private var analyzingSong = false

    var filteredSongs: [Song] {
        if searchText.isEmpty {
            return appState.songs
        } else {
            return appState.songs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if appState.isLoadingSongs {
                    ProgressView("Loading your music library...")
                        .padding()
                } else if appState.songs.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No songs found")
                            .font(.title2)

                        Text("Make sure you have music in your Apple Music library")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List(filteredSongs) { song in
                        SongRow(song: song)
                            .onTapGesture {
                                selectSong(song)
                            }
                    }
                    .searchable(text: $searchText, prompt: "Search songs or artists")
                }
            }
            .navigationTitle("Select Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGameplay) {
                if let song = selectedSong {
                    GameplayView(song: song)
                }
            }
            .overlay {
                if analyzingSong {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()

                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Analyzing song...")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text("Detecting BPM, genre, and energy")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(40)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)
                    }
                }
            }
        }
    }

    private func selectSong(_ song: Song) {
        selectedSong = song

        // Analyze song if not already analyzed
        if song.features == nil {
            analyzingSong = true

            Task {
                let analyzedSong = await appState.analyzeSong(song)

                // Update in list
                if let index = appState.songs.firstIndex(where: { $0.id == song.id }) {
                    appState.songs[index] = analyzedSong
                }

                selectedSong = analyzedSong
                analyzingSong = false

                // Show gameplay
                showingGameplay = true
            }
        } else {
            showingGameplay = true
        }
    }
}

struct SongRow: View {

    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            // Album art placeholder
            ZStack {
                Color.purple.opacity(0.2)

                Image(systemName: "music.note")
                    .foregroundColor(.purple)
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    if let bpm = song.bpm {
                        Label("\(Int(bpm)) BPM", systemImage: "metronome")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let genre = song.genre {
                        Text(genre.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            Text(song.displayDuration)
                .font(.caption)
                .foregroundColor(.secondary)

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
