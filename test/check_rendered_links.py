"""Check preview URL prefixes, then local destinations with HTMLProofer."""

import json
import posixpath
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit

BASEURL = "/__linkcheck__"


class PreviewLinks(HTMLParser):
    def __init__(self, output_path, source):
        super().__init__()
        self.page_url = f"https://linkcheck.invalid{BASEURL}/{output_path}"
        self.source = source
        self.errors = []

    def handle_starttag(self, tag, attributes):
        attributes = dict(attributes)
        urls = []
        if tag in ("a", "link") and "href" in attributes:
            urls.append(attributes["href"])
        if tag in ("img", "script", "source", "video", "audio", "iframe"):
            if "src" in attributes:
                urls.append(attributes["src"])
            for candidate in (attributes.get("srcset") or "").split(","):
                if candidate.strip():
                    urls.append(candidate.split()[0])
        for url in urls:
            if not url:
                continue
            parsed = urlsplit(url)
            if parsed.scheme or parsed.netloc:
                continue
            path = posixpath.normpath(unquote(urlsplit(urljoin(self.page_url, url)).path))
            if path == BASEURL or path.startswith(BASEURL + "/"):
                continue
            self.errors.append(
                f'{self.source}: link {url!r} is missing the expected '
                f'{BASEURL + "/"!r} prefix (HTML line {self.getpos()[0]})'
            )


def check(directory):
    directory = Path(directory).resolve()
    sources = json.loads((directory / ".sources.json").read_text())
    errors = []
    for file in sorted(directory.rglob("*.html")):
        output_path = file.relative_to(directory).as_posix()
        parser = PreviewLinks(output_path, sources.get(output_path, output_path))
        parser.feed(file.read_text())
        errors.extend(parser.errors)
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1

    # The separate prefix check is necessary: swapping the prefix alone would
    # also accept an incorrect URL that never contained it in the first place.
    result = subprocess.run(
        [
            "htmlproofer", str(directory), "--disable-external",
            "--swap-urls", f"^{BASEURL}/:/",
            "--check-internal-hash", "--ignore-missing-alt", "--no-enforce-https",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    stdout, stderr = result.stdout, result.stderr
    for output_path, source in sources.items():
        generated_file = str(directory / output_path)
        label = f"{source} (rendered {output_path})"
        stdout = stdout.replace(generated_file, label)
        stderr = stderr.replace(generated_file, label)
    print(stdout, end="")
    print(stderr, end="", file=sys.stderr)
    return result.returncode


if __name__ == "__main__":
    sys.exit(check(sys.argv[1]))
