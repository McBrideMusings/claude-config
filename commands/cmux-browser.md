---
description: Open a URL in cmux browser and take a snapshot for inspection
argument_name: url
---

Use cmux browser automation to open and inspect the given URL. Follow these steps:

1. First run `cmux browser identify` to list existing surfaces
2. For each surface, run `cmux browser surface:N url` to check if one is already on the same site/origin
3. If a matching tab exists, run `cmux browser surface:N navigate $ARGUMENTS --snapshot-after` to reuse it
4. If no matching tab, run `cmux browser open $ARGUMENTS` to open a new one, then `cmux browser identify` to get the surface ID
5. Run `cmux browser surface:N snapshot --interactive --compact` to get the page structure
6. Run `cmux browser surface:N screenshot --out /tmp/cmux-preview.png` to capture a visual screenshot
7. Read the screenshot file with the Read tool to show the user what the page looks like

Use the cmux-browser skill for the full command reference.
