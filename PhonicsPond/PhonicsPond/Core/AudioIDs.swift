import Foundation

/// Spoken instructions and feedback. Raw value = recording file name without extension.
/// Every case must have a row in docs/design/level-1-audio-manifest.csv
/// (checked by tools/validate_content.py and AudioCatalogTests).
enum Prompt: String, CaseIterable {
    case tapToStart = "prompt_tap_to_start"
    case welcomeBack = "prompt_welcome_back"
    case todayFourSounds = "prompt_today_four_sounds"
    case tapGlowingStone = "prompt_tap_glowing_stone"
    case tapAPicture = "prompt_tap_a_picture"
    case tapToHearSound = "prompt_tap_to_hear_sound"
    case yourTurn = "prompt_your_turn"
    case traceTheLetter = "prompt_trace_the_letter"
    case listenWhatWord = "prompt_listen_what_word"
    case buildSat = "prompt_build_sat"
    case tryFirstSound = "prompt_try_first_sound"
    case tryMiddleSound = "prompt_try_middle_sound"
    case tryLastSound = "prompt_try_last_sound"
    case saySoundsSayWord = "prompt_say_sounds_say_word"
    case changeMakePat = "prompt_change_make_pat"
    case changedOneSound = "prompt_changed_one_sound"
    case whatSoundAtEnd = "prompt_what_sound_at_end"
    case thatsIt = "prompt_thats_it"
    case readTheWords = "prompt_read_the_words"
    case grownUpTime = "prompt_grown_up_time"
    case stopForToday = "prompt_stop_for_today"
    case pickASticker = "prompt_pick_a_sticker"
    case cueS = "cue_s"
    case cueShortA = "cue_short_a"
    case cueT = "cue_t"
    case cueP = "cue_p"

    /// The line as shown on screen (the recording says the same words).
    var text: String {
        switch self {
        case .tapToStart: return "Tap to start."
        case .welcomeBack: return "Welcome back. Tap to go on."
        case .todayFourSounds: return "Today you meet four sounds."
        case .tapGlowingStone: return "Tap the glowing stone."
        case .tapAPicture: return "Tap a picture."
        case .tapToHearSound: return "Tap to hear the sound."
        case .yourTurn: return "Your turn."
        case .traceTheLetter: return "Trace the letter."
        case .listenWhatWord: return "Listen. What word is it?"
        case .buildSat: return "Build sat."
        case .tryFirstSound: return "Try the first sound."
        case .tryMiddleSound: return "Try the middle sound."
        case .tryLastSound: return "Try the last sound."
        case .saySoundsSayWord: return "Say the sounds. Now say the word."
        case .changeMakePat: return "Change one sound. Make pat."
        case .changedOneSound: return "You changed one sound and made a new word!"
        case .whatSoundAtEnd: return "What sound do you hear at the end?"
        case .thatsIt: return "That's it!"
        case .readTheWords: return "Read the words."
        case .grownUpTime: return "Grown-up time!"
        case .stopForToday: return "Stop for today?"
        case .pickASticker: return "Pick a sticker."
        case .cueS: return "Snake sound. Teeth together."
        case .cueShortA: return "Open wide. Quick!"
        case .cueT: return "Tongue taps. Feel the puff."
        case .cueP: return "Lips pop. Feel the puff."
        }
    }

    static func tryPosition(_ slot: Int, of count: Int) -> Prompt {
        switch SlotPosition.name(slot, of: count) {
        case "first": return .tryFirstSound
        case "last": return .tryLastSound
        default: return .tryMiddleSound
        }
    }
}

/// Non-teaching sounds. Never played over speech.
enum Effect: String, CaseIterable {
    case stickerChime = "effect_sticker_chime"
}

/// Audio IDs derived from curriculum data.
enum AudioID {
    static func blend(_ word: String) -> String {
        "blend_" + word.map { String($0) }.joined(separator: "_")
    }

    /// The mouth/action cue spoken after a sound card's first play.
    static func cue(for letter: String) -> Prompt? {
        switch letter {
        case "s": return .cueS
        case "a": return .cueShortA
        case "t": return .cueT
        case "p": return .cueP
        default: return nil
        }
    }
}

/// What a sound card shows next to the letter.
struct SoundCue {
    let mouthCaption: String
    let actionCaption: String
    let mouthAsset: String
    let actionAsset: String

    static func forLetter(_ letter: String) -> SoundCue {
        switch letter {
        case "s": return SoundCue(mouthCaption: "teeth together", actionCaption: "snake hand", mouthAsset: "mouth_s", actionAsset: "action_s")
        case "a": return SoundCue(mouthCaption: "open wide", actionCaption: "ants on your arm", mouthAsset: "mouth_a", actionAsset: "action_a")
        case "t": return SoundCue(mouthCaption: "tongue taps", actionCaption: "tap the table", mouthAsset: "mouth_t", actionAsset: "action_t")
        case "p": return SoundCue(mouthCaption: "lips pop", actionCaption: "blow a candle", mouthAsset: "mouth_p", actionAsset: "action_p")
        default: return SoundCue(mouthCaption: "", actionCaption: "", mouthAsset: "", actionAsset: "")
        }
    }
}
