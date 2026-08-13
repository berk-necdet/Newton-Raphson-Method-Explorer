# Newton-Raphson Method Explorer

This release provides a MATLAB application with an English-language interface, featuring 18 predefined Newton-Raphson scenarios and a cursor-aware custom function calculator.

## Files

- `NewtonRaphsonApp.m`: A fully functional, single-file MATLAB application.
- `buildStandalone.m`: Builds a Windows `.exe` and installer package using MATLAB Compiler.
- `README.md`: This usage and distribution guide.

## Running in MATLAB

Set the MATLAB Current Folder to this directory, then run:

```matlab
NewtonRaphsonApp
```

To run the built-in tests:

```matlab
NewtonRaphsonApp('SelfTest', true)
```

## Using Custom Function and the Cursor

1. Select **CUSTOM FUNCTION** from the panel on the left.
2. Click **OPEN FUNCTION CALCULATOR**.
3. Select `f(x)` or `f'(x)` from the drop-down list at the top. Each expression maintains its own cursor position.
4. Use `<` and `>` to move within the expression. The on-screen `|` indicates the cursor position.
5. **DEL** deletes the recognized function token immediately to the left of the cursor (for example, `acos(`) or a single character.
6. **FWD DEL** deletes the token or character immediately to the right of the cursor.
7. New input is inserted at the cursor position.
8. After clicking **APPLY AND CLOSE**, click **RUN** in the main window.

Example function for the Interior Goat Problem:

```text
x^2*acos(x/2)+acos(1-x^2/2)-x/2*sqrt(4-x^2)-pi/2
```

Its analytical derivative is:

```text
2*x*acos(x/2)
```

With `x0 = 1.2`, the result should be approximately `1.158728473`.

## Behavior

- Selecting a scenario only loads it; the solution begins only when you click **RUN**.
- **STOP** safely stops an animation in progress.
- Both **Analytical** and **Numerical** derivative options are available.
- You can adjust the animation delay, tolerance, maximum number of iterations, and plot limits.
- The live Newton calculation, tangent-line visualization, results, and iteration table update together.

## Building a Standalone Windows Application Without MATLAB

From the MATLAB Command Window in this directory, run:

```matlab
buildStandalone
```

MATLAB Compiler is required. The script:

- creates `NewtonRaphsonExplorer.exe` in `standalone_build`;
- creates the `NewtonRaphsonExplorerInstaller` installer package in `installer`;
- configures the smaller installer package to download MATLAB Runtime from the internet during installation.

The target computer does not require a licensed MATLAB installation, but it does require the MATLAB Runtime version that matches the build. The compiled application is platform-specific; this script produces a Windows build.

You can also use the graphical interface: run `standaloneApplicationCompiler` in MATLAB, select `NewtonRaphsonApp.m` as the main file, and set the application type to **Standalone Windows Application**.

## About `.mlapp` Files and MATLAB App Packages

This version is a single-file `.m` application that uses a programmatic `uifigure` interface and is suitable for standalone compilation. In R2025a and later, the current sharing format for new MATLAB Apps is an `.mltbx` package created in App Designer from `.mlapp` source. Because there is no supported command that automatically and reliably converts the source code into a binary `.mlapp` file, this release does not include a fake or manually generated `.mlapp` file.

## Phone and Web Use

A `uifigure`-based desktop application cannot run directly on Android or iPhone. There are two practical options for phone access:

1. App Designer port + MATLAB Web App Server: Rebuild the application as an `.mlapp`, create a web app archive with MATLAB Compiler, and deploy it to MATLAB Web App Server. Users can then connect through a phone browser. Web App Server is designed for trusted intranet environments.
2. Web-based rewrite: Port the Newton engine to JavaScript/TypeScript or a server API, use Plotly or D3 for plotting, and build the interface with responsive HTML/CSS. This is the more flexible option for public internet access and mobile use.

Short MATLAB Web App Server roadmap:

1. Port the programmatic interface to App Designer components.
2. Separate the cursor editor, scenario library, and Newton engine into App Designer callbacks and methods.
3. Add a responsive, single-column layout for phone screens.
4. Use **Share > Web App** in App Designer to generate the `.ctf` archive.
5. Upload it to an authorized MATLAB Web App Server and test it in real phone browsers.

## Compatibility Note

This version has been validated on MATLAB R2026a using Code Analyzer, the built-in self-test, and an invisible `uifigure` launch test.

### R2026a Runtime Fix

The initial installer could fail at application startup with a “The specified module could not be found” error because the R2026a Runtime web installer omitted `libmwflproxycredentialapi.dll`. The corrected package installs this DLL alongside the application.

### Version 1.1.0

The information panel in the upper-right corner has been redesigned. Below the Newton-Raphson formula, the `f(x)` function for the selected scenario or Custom Function mode is continuously displayed in turquoise, while its `f'(x)` derivative is displayed in yellow. When **Numerical** derivative mode is selected, the derivative line indicates that a central-difference approximation is being used.
