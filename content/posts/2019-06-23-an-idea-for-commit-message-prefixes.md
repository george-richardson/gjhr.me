---
title:  "An idea for commit message prefixes"
date:   2019-06-23 11:00:00 +0000
---

I always want to be able to see what type of change a commit contains at a glance but also don't want to waste the precious characters that can fit on the first line. There have already been attempts to [standardise commit message formats](https://www.conventionalcommits.org/en/v1.0.0-beta.4/) but I have usually found the rules are either overbearing or the boilerplate is too long for my tastes. As such here is my attempt at a system that I will be using in my personal projects starting from the commit of this blog post!

Every commit can start with one or more of the following symbols which describe its content:
* `+` An additive commit, usually adds a new feature.
* `-` A subtractive commit, usually removes a bug.
* `=` A refactor commit, changes code but not functionality.
* `/` A miscellaneous commit, fix a typo, add a comment etc.
* `!` A breaking commit, breaks an interface or contract.

Each of the above definitions is a loose guideline so you can combine these together where it makes sense e.g. `=- Refactored WidgetClass to improve performance, fixed high CPU usage bug`. 

Sometimes when working on personal projects I can get sloppy and combine multiple logical changes into a single commit, this system will allow me to write something like `+-/ Added 'My Widgets' page, fixed login timeout, spell 'flagrant correctly'` so that future me doesn't hate lazy past me quite so much.