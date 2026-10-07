function ydl
	yt-dlp "$argv" --cookies-from-browser firefox --js-runtimes deno --remote-components ejs:github
end
