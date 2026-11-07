abbr nvenc "sys-env ffmpeg_nv -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 -c:a copy -c:v hevc_nvenc output.mp4"
abbr vaapi "sys-env time ffmpeg_va -vaapi_device /dev/dri/renderD128 -i input.mp4 -vf 'format=nv12,hwupload' -c:v av1_vaapi -b:v 3M -c:a opus -b:a 64k -strict -2 output.webm"
