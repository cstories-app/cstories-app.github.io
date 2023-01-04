# Welcome to CStories.App

This website will feature an application for communities to build stories using data to inform offshore energy planning of their priorities.

## Coding Conventions


### Loading Packages in R

@bbest: I like the convention of using `librarian::shelf()` over `library()`, since packages will automatically install if missing. Plus you can reference Github repos to install from source like `IntegralEnvision/integral` without even needing to wrap in quotes. I tend to put these in alphabetical order so I can easily see what's loaded and needs to be added when using something new.
