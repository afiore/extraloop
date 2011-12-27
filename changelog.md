# Project Changelog

## Version 0.1 (*27-12-2011*)

- Scraper Hooks have been been improved and refactored into a reusable module. It is now possible to set
  more than one block for each hook.
- Extractor blocks and hooks handles are now run within the actual scraper's scope using `#instance_exec`

