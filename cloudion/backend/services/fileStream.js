// =============================================================================
// fileStream.js — shared helper for serving a file the backend has already
// had a Bash script validate.
//
// "View" and "download" both start from the exact same place: a download
// script (personal_download.sh / one_to_one_download.sh / group_download.sh
// / global_download.sh) resolves the path, confirms it exists inside the
// caller's authorized area, and hands back {PATH, FILE_NAME, FILE_TYPE}.
// Bash's job stops there — whether the browser then displays the file
// inline or prompts a download is purely an HTTP header choice, which is
// an application/presentation concern, not a filesystem operation. So we
// don't need a separate Bash script for "view"; we just serve the same
// validated path differently.
// =============================================================================

// Only these MIME families render inline reliably in a browser tab. Anything
// else (zip, docx, exe, ...) still gets served without forcing a download
// dialog, but the browser will fall back to downloading it if it doesn't
// know how to display it — same as clicking a normal link.
function sendInline(res, result) {
  const mimeType = result.data.FILE_TYPE || 'application/octet-stream';
  const fileName = result.data.FILE_NAME || 'file';

  res.setHeader('Content-Type', mimeType);
  // 'inline' asks the browser to render/display it if it can, instead of
  // forcing a Save As dialog the way res.download()'s 'attachment' does.
  res.setHeader('Content-Disposition', `inline; filename="${fileName.replace(/"/g, '')}"`);
  return res.sendFile(result.data.PATH);
}

module.exports = { sendInline };
