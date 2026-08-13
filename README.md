# Newton-Raphson Method Explorer

An interactive MATLAB application for exploring Newton-Raphson convergence, failure cases, custom nonlinear equations, and numerical differentiation. The English-language interface includes 18 predefined teaching scenarios, an animated iteration view, and a cursor-aware scientific function builder.

## Download / Quick Start

| I want to... | Use this file | What to know |
| --- | --- | --- |
| Install the Windows application without MATLAB | [NewtonRaphsonExplorerInstaller.exe](NewtonRaphsonExplorerInstaller.exe) | **Recommended for most Windows users.** Licensed MATLAB is not required. The installer downloads and installs the compatible MATLAB Runtime during setup when needed, so an internet connection may be required. |
| Run or modify the application in MATLAB | [NewtonRaphsonApp.m](NewtonRaphsonApp.m) | Set the MATLAB Current Folder to the repository directory and run `NewtonRaphsonApp`. |
| Use the compiled portable Windows build | [NewtonRaphsonExplorer_Portable.zip](NewtonRaphsonExplorer_Portable.zip) | MATLAB itself is not required, but a compatible MATLAB Runtime may need to be installed separately. If you are unsure, use the installer above. |
| Open the project visualizations | [DESMOS.md](DESMOS.md) | Includes the Desmos links used for the Newton-Raphson and Interior Goat Problem visualizations. |

The packaged source archive is also available as [NewtonRaphsonApp_Source.zip](NewtonRaphsonApp_Source.zip).

> [!IMPORTANT]
> A compiled MATLAB application can run without a licensed MATLAB installation, but it still requires the compatible MATLAB Runtime. “Portable” means that no application installer is used; it does not mean that the build is Runtime-free or cross-platform.

## Screenshots




<img width="2559" height="1439" alt="Newton-Raphson Method Explorer main interface" src="https://github.com/user-attachments/assets/8d97cc68-6db5-4300-a81b-c4ec9cdd3dd2" />




<img width="2559" height="1439" alt="Scientific Function Builder with cursor editing" src="https://github.com/user-attachments/assets/bcc7081e-0086-45ef-9d3b-9d2e39b22478" />




<img width="2559" height="1439" alt="Newton-Raphson failure scenario" src="https://github.com/user-attachments/assets/2afd2550-66d1-4db5-a023-7a47c1f1c5d9" />



<img width="3838" height="1850" alt="Interior Goat Problem Desmos visualization" src="https://github.com/user-attachments/assets/3c7848f7-76bf-47e2-a527-308fcc174d59" />




## Highlights

- **18 predefined teaching scenarios** covering zero or small derivatives, cycles, divergence, domain violations, multiple roots, slow convergence, overflow, asymptotes, non-differentiable points, false convergence, and initial-guess sensitivity.
- **Cursor-aware scientific function builder** for entering custom `f(x)` and `f'(x)` expressions.
- **Independent cursor positions** for `f(x)` and `f'(x)`, with in-expression left/right navigation and a visible `|` cursor.
- **Cursor-position insertion**, token-aware backspace, and forward delete for scientific-function tokens such as `acos(` and `sqrt(`.
- **Analytical and numerical derivative modes**; numerical mode uses a central-difference approximation.
- **Animated Newton iterations** with a live tangent-line construction, results display, and synchronized iteration table.
- **RUN-only execution**: selecting a scenario loads its parameters but does not begin the iteration.
- **STOP control** for safely ending an animation in progress.
- **Interior Goat Problem example** with matching [Desmos visualizations](DESMOS.md).

## Repository Files

- [`NewtonRaphsonApp.m`](NewtonRaphsonApp.m): Fully functional, single-file MATLAB application built with a programmatic `uifigure` interface.
- [`buildStandalone.m`](buildStandalone.m): Builds the standalone Windows executable and installer using MATLAB Compiler.
- [`NewtonRaphsonExplorerInstaller.exe`](NewtonRaphsonExplorerInstaller.exe): Recommended Windows installer for users without MATLAB; downloads and installs the compatible MATLAB Runtime when needed.
- [`NewtonRaphsonExplorer_Portable.zip`](NewtonRaphsonExplorer_Portable.zip): Portable compiled Windows build; a compatible MATLAB Runtime may need to be installed separately.
- [`NewtonRaphsonApp_Source.zip`](NewtonRaphsonApp_Source.zip): Downloadable archive of the application source files.
- [`DESMOS.md`](DESMOS.md): Desmos visualization links, including the Interior Goat Problem.
- [`README.md`](README.md): Project overview, setup, usage, build, deployment, and compatibility documentation.
- [`LICENSE`](LICENSE): Project license terms.

## Running in MATLAB

Set the MATLAB Current Folder to the repository directory, then run:

```matlab
NewtonRaphsonApp
```

To run the built-in tests:

```matlab
NewtonRaphsonApp('SelfTest', true)
```

## Using the Custom Function Builder and Cursor

1. Select **CUSTOM FUNCTION** from the panel on the left.
2. Click **OPEN FUNCTION CALCULATOR**.
3. Select `f(x)` or `f'(x)` from the drop-down list at the top. Each expression maintains its own cursor position.
4. Use `<` and `>` to move within the expression. The on-screen `|` indicates the cursor position.
5. **DEL** deletes the recognized function token immediately to the left of the cursor—for example, `acos(`—or a single character.
6. **FWD DEL** deletes the token or character immediately to the right of the cursor.
7. New input is inserted at the current cursor position.
8. Click **APPLY AND CLOSE**, then click **RUN** in the main window to start the calculation.

## Interior Goat Problem Example

The application can solve the nonlinear equation arising from the Interior Goat Problem. See the accompanying geometry and area visualizations in [DESMOS.md](DESMOS.md).

Enter the following function in the Scientific Function Builder:

```text
x^2*acos(x/2)+acos(1-x^2/2)-x/2*sqrt(4-x^2)-pi/2
```

Use the analytical derivative:

```text
2*x*acos(x/2)
```

With `x0 = 1.2`, the result should be approximately:

```text
1.158728473
```

## Application Behavior

- Selecting a scenario only loads the scenario and its parameters; the solution begins only when **RUN** is clicked.
- **STOP** safely stops an animation in progress.
- Both **Analytical** and **Numerical** derivative options are available.
- Animation delay, tolerance, maximum iteration count, and plot limits can be adjusted.
- The live Newton calculation, tangent-line visualization, result display, and iteration table update together.
- The upper-right information panel continuously displays the active `f(x)` and `f'(x)` expressions.

## Windows Installer, Standalone Build, and MATLAB Runtime

The standalone Windows application does **not** require MATLAB itself or a MATLAB license on the target computer. It does require the MATLAB Runtime version compatible with the release build.

### Recommended: Windows Installer

Use [`NewtonRaphsonExplorerInstaller.exe`](NewtonRaphsonExplorerInstaller.exe) if MATLAB is not installed. The installer is configured to download and install the compatible MATLAB Runtime during setup when it is not already available. Because the installer uses web delivery for the Runtime components, the target computer may need an internet connection during installation.

### Alternative: Portable Build

[`NewtonRaphsonExplorer_Portable.zip`](NewtonRaphsonExplorer_Portable.zip) contains the compiled application without a conventional application installer. MATLAB itself is not required, but the compatible MATLAB Runtime may need to be installed separately before the application can start. The portable archive is a Windows build and is not a cross-platform package.

## Building the Standalone Windows Application

MATLAB Compiler is required to create a new standalone build. From the MATLAB Command Window in this repository directory, run:

```matlab
buildStandalone
```

The script:

- creates `NewtonRaphsonExplorer.exe` in `standalone_build`;
- creates the `NewtonRaphsonExplorerInstaller` installer package in `installer`;
- configures the smaller installer to download MATLAB Runtime from the internet during installation; and
- includes the R2026a Runtime compatibility dependency used by this release.

The resulting compiled application is platform-specific; this build script produces a Windows application.

You can also use the MATLAB graphical compiler interface. Run `standaloneApplicationCompiler`, select `NewtonRaphsonApp.m` as the main file, and set the application type to **Standalone Windows Application**.

## About `.mlapp` Files and MATLAB App Packages

This version is a single-file `.m` application that uses a programmatic `uifigure` interface and is suitable for standalone compilation. It is not an App Designer `.mlapp` project.

In R2025a and later, the current sharing format for new MATLAB Apps is an `.mltbx` package created in App Designer from `.mlapp` source. Because there is no supported command that automatically and reliably converts this programmatic source into a binary `.mlapp` file, this release does not include a fake or manually generated `.mlapp` file.

## Phone and Web Use

A `uifigure`-based desktop application cannot run directly as an Android or iOS application. There are two practical approaches for phone or browser access:

1. **App Designer port + MATLAB Web App Server:** Rebuild the interface as an `.mlapp`, create a web app archive with MATLAB Compiler, and deploy it to MATLAB Web App Server. Users can then connect through a phone browser. MATLAB Web App Server is intended for trusted intranet environments.
2. **Web-based rewrite:** Port the Newton engine to JavaScript/TypeScript or expose it through a server API, use Plotly or D3 for plotting, and create a responsive HTML/CSS interface. This is the more flexible option for public internet access and mobile use.

A short MATLAB Web App Server roadmap:

1. Port the programmatic interface to App Designer components.
2. Separate the cursor editor, scenario library, and Newton engine into App Designer callbacks and methods.
3. Add a responsive, single-column layout for phone screens.
4. Use **Share > Web App** in App Designer to generate the `.ctf` archive.
5. Upload it to an authorized MATLAB Web App Server and test it in real phone browsers.

## Compatibility and Version Notes

### MATLAB R2026a

This version was validated on MATLAB R2026a using Code Analyzer, the built-in self-test, and an invisible `uifigure` launch test. The prebuilt standalone packages target the compatible R2026a MATLAB Runtime on Windows.

### R2026a Runtime Fix

The initial installer could fail at application startup with a “The specified module could not be found” error because the R2026a Runtime web installer omitted `libmwflproxycredentialapi.dll`. The corrected package installs this DLL alongside the application.

### Version 1.1.0

The information panel in the upper-right corner was redesigned. Below the Newton-Raphson formula, the `f(x)` function for the selected scenario or Custom Function mode is continuously displayed in turquoise, while its `f'(x)` derivative is displayed in yellow. When **Numerical** derivative mode is selected, the derivative line indicates that a central-difference approximation is being used.

## License

See [`LICENSE`](LICENSE) for the project license terms.
