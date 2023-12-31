Param(
    [Parameter(Position=1)]
    [string]$dir
)
$ext = (dir "$dir").Extension
$file_name = (dir "$dir").BaseName
$encoder = "h264_nvenc"
if ($ext -eq '.webm') {
$mp4_name = $dir -replace "$ext",'.mp4'
ffmpeg.exe -y -i "$dir" -c:v $encoder -c:a aac $mp4_name
} else {
$mp4_name = $dir
}
$target_video_size_MB=24
$origin_duration_s = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$mp4_name"
$origin_audio_bitrate_kbit_s = ffprobe.exe -v error -pretty -show_streams -select_streams a "$mp4_name" | Select-string -Pattern "(?<=^bit_rate\=)\d*\.\d*"
$origin_audio_bitrate_kbit_s = $origin_audio_bitrate_kbit_s -replace 'bit_rate=','' -replace ' Kbit/s',''
$target_audio_bitrate_kbit_s = [float]$origin_audio_bitrate_kbit_s
$target_video_bitrate_kbit_s = ($target_video_size_MB * 8192.0) / ( 1.048576 * [float]$origin_duration_s ) - $target_audio_bitrate_kbit_s
$target_audio_bitrate_kbit_s = [string]$target_audio_bitrate_kbit_s+'k'
$target_video_bitrate_kbit_s = [string]$target_video_bitrate_kbit_s+'k'
$new_name = "$mp4_name" -replace '.mp4',''
$new_name = "$new_name"+'_d.mp4'
ffmpeg.exe -y -i "$mp4_name" -c:v $encoder -b:v $target_video_bitrate_kbit_s -pass 1 -passlogfile "$file_name" -an -f mp4 NUL; ffmpeg.exe -y -i "$mp4_name" -c:v $encoder -pass 2 -passlogfile "$file_name" -b:v $target_video_bitrate_kbit_s -c:a aac -b:a $target_audio_bitrate_kbit_s "$new_name"
rm ./"$file_name"-*.log*
if ($ext -eq '.webm') {
rm "$mp4_name"
}
