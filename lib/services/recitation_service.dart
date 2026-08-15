import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// What the play button should currently show.
enum RecitationState { idle, loading, playing }

/// Streams ayah recitation from the Al Quran Cloud / Islamic Network CDN.
///
/// One player instance is reused for the whole feed — cards never own a
/// player of their own. The reciter is a single constant here so swapping it
/// (or making it a user setting) never touches the UI.
class RecitationService {
  RecitationService() {
    _player.playerStateStream.listen(_onPlayerState);
  }

  /// Mishary Rashid Alafasy, 128kbps.
  static const _reciter = 'ar.alafasy';
  static const _bitrate = 128;

  static String audioUrlFor(int globalAyahNumber) =>
      'https://cdn.islamic.network/quran/audio/$_bitrate/$_reciter/'
      '$globalAyahNumber.mp3';

  final _player = AudioPlayer();
  final _stateController = StreamController<RecitationState>.broadcast();

  /// The ayahs queued for the currently playing feed item, and how far into
  /// them playback has reached — a feed item may hold several consecutive
  /// ayahs, which play back to back.
  List<int> _queue = const [];
  int _queueIndex = 0;

  /// Identifies which feed item owns the current playback, so a card can ask
  /// "is it me that's playing?" without tracking player internals.
  Object? _activeOwner;

  RecitationState _state = RecitationState.idle;

  Stream<RecitationState> get stateStream => _stateController.stream;
  RecitationState get state => _state;
  Object? get activeOwner => _activeOwner;

  void _emit(RecitationState next) {
    if (_state == next) return;
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  void _onPlayerState(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      _advance();
      return;
    }
    if (!playerState.playing) {
      // Paused, or idle before the first play — either way not playing.
      if (_state != RecitationState.loading) _emit(RecitationState.idle);
      return;
    }
    switch (playerState.processingState) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        _emit(RecitationState.loading);
      case ProcessingState.ready:
        _emit(RecitationState.playing);
      case ProcessingState.idle:
      case ProcessingState.completed:
        break;
    }
  }

  /// Plays the next queued ayah, or stops once the feed item is exhausted.
  Future<void> _advance() async {
    if (_queueIndex >= _queue.length - 1) {
      await stop();
      return;
    }
    _queueIndex++;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    _emit(RecitationState.loading);
    try {
      await _player.setUrl(audioUrlFor(_queue[_queueIndex]));
      await _player.play();
      _preloadNext();
    } catch (_) {
      // A dead CDN response or offline device shouldn't leave the button
      // stuck spinning — fall back to the idle/play state.
      await stop();
    }
  }

  /// Warms the network cache for the following ayah without disturbing the
  /// main player, so a multi-ayah item doesn't stall between ayahs.
  void _preloadNext() {
    final next = _queueIndex + 1;
    if (next >= _queue.length) return;
    unawaited(() async {
      final warmer = AudioPlayer();
      try {
        await warmer.setUrl(audioUrlFor(_queue[next]));
      } catch (_) {
        // Best-effort only — the real fetch will retry when it's this
        // ayah's turn.
      } finally {
        await warmer.dispose();
      }
    }());
  }

  /// Starts [ayahNumbers] for [owner], replacing whatever was playing.
  Future<void> play({
    required Object owner,
    required List<int> ayahNumbers,
  }) async {
    if (ayahNumbers.isEmpty) return;
    await _player.stop();
    _activeOwner = owner;
    _queue = List.unmodifiable(ayahNumbers);
    _queueIndex = 0;
    await _playCurrent();
  }

  Future<void> pause() async {
    await _player.pause();
    _emit(RecitationState.idle);
  }

  Future<void> resume() async {
    await _player.play();
  }

  /// Halts playback and clears ownership — used when swiping to another verse
  /// so the new card starts from a clean play state.
  Future<void> stop() async {
    await _player.stop();
    _activeOwner = null;
    _queue = const [];
    _queueIndex = 0;
    _emit(RecitationState.idle);
  }

  Future<void> dispose() async {
    await _stateController.close();
    await _player.dispose();
  }
}
