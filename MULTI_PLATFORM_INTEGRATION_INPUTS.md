# Minimum Inputs Needed for Direct Integration

I can wire the opening engine into the real app once these project-specific inputs are available.

Please provide only these minimal items from the existing codebase:

1. The app entry file or startup file for `web`
2. The app entry file or startup file for `windows`
3. The app entry file or startup file for `android`
4. The current model invocation service or engine service file
5. The current local storage or database initialization file

If the app is Flutter or a shared cross-platform framework, even better:

- send the main app bootstrap file
- send the current model service file
- send the storage init file

With those files, I can stop writing reference assets and start patching the actual engine directly.
