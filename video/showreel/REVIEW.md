# Review: PACE showreel "One morning" (render 2026-11-19)

Output: renders/pace-showreel.mp4, 1920x1080, 30 fps, 30.0 s, H.264 + AAC, 10.9 MB.
Audio measured (not heard): -15.8 LUFS integrated, peak -1.6 dBFS.

Creative calls: storyline A ("One morning"). Not built: B "Stones stack", C "Slow is fast" (STORYLINES.md).
Voice: ElevenLabs "Sarah" (7 lines). Music: ElevenLabs Music API is paid-only on this key, so the
bed is ElevenLabs sound-effect loops (piano intro, two 96 BPM grooves, ending chord) stitched in
ffmpeg and ducked under the voice. SFX: ElevenLabs, plus Pixabay pop/click/key from the HyperFrames bundle.
Screens: real app rendered at 3x by a local, git-ignored harness (pace_app/test/zz_shots/reel_test.dart).

Fixed after the first look: frame 0 thumbnail, clock/Tuck crowding, empty timeline card,
double ring on the Focus carry, wordmark cap dots, muddy grey floods (now circle wipes), end card size.

Kept on purpose: line_unread warnings on the clock digits (fast flips are the point);
text_occluded infos (screens under wipes during transitions).

Weakest shot: the music bed. It's looped SFX, more repetitive than composed music.
With a paid ElevenLabs plan, replace assets/music/bed.wav with a real 30 s composition.
