extends Node

@onready var pitch_label: Label = %PitchLabel
@onready var pitch_marker: Marker2D = $PitchMarker
@onready var volume_label: Label = %VolumeLabel
@onready var waveform_line: Line2D = $WaveformLine

var capture: AudioEffectCapture
var sample_rate = 44100  # Standard sample rate
var buffer_size = 1024  # Number of audio samples to process

func _ready():
	# Get the capture effect
	var bus_idx = AudioServer.get_bus_index("Record")
	capture = AudioServer.get_bus_effect(bus_idx, 0) as AudioEffectCapture
	var input_device = AudioServer.get_input_device_list()[0]
	print("Using input device:", input_device)
	AudioServer.input_device = input_device
	#print(AudioServer.get_input_device_list())
	
func _process(_delta):
	if capture and capture.get_frames_available() > 0:
		var buffer = capture.get_buffer(capture.get_frames_available())
		# Print first few samples to check if we get meaningful values
		var normalized_buffer = [x * 1000 for x in buffer]
		print("Normalized Samples:", normalized_buffer.slice(0, min(buffer.size(), 10)))
#
#func _process(_delta):
	#if capture.get_frames_available() >= buffer_size:
		#var buffer = capture.get_buffer(buffer_size)
		#var volume = calculate_volume(buffer)
		#var pitch = detect_pitch(buffer)
#
		## Print debug info
		##print("Volume:", volume, " | Pitch:", pitch)
#
		## Update labels
		#pitch_label.text = "Pitch: " + "%.2f" % pitch + " Hz"
		#volume_label.text = "Volume: " + "%.2f" % volume
#
		## Update waveform visualization
		#update_waveform(buffer)

func calculate_volume(samples: PackedVector2Array) -> float:
	var sum_squares = 0.0
	for sample in samples:
		sum_squares += sample.x * sample.x  # Use left channel only
	return sqrt(sum_squares / samples.size()) if samples.size() > 0 else 0.0

func update_waveform(samples: PackedVector2Array):
	waveform_line.clear_points()
	var width = 400  # Width of waveform display
	var height = 100  # Height of waveform display
	for i in range(min(samples.size(), width)):  
		var x = i  # X position in waveform
		var y = height / 2 + samples[i].x * height  # Scale amplitude to screen
		waveform_line.add_point(Vector2(x, y))

func detect_pitch(samples: PackedVector2Array) -> float:
	var min_period = int(sample_rate / 2000.0)  # Max frequency ~2kHz
	var max_period = int(sample_rate / 60.0)  # Min frequency ~60Hz
	var best_period = 0
	var best_correlation = 0

	for period in range(min_period, max_period):
		var correlation = 0.0
		for i in range(samples.size() - period):
			correlation += samples[i].x * samples[i + period].x
		
		if correlation > best_correlation:
			best_correlation = correlation
			best_period = period

	if best_period > 0:
		return sample_rate / best_period
	return 0.0
