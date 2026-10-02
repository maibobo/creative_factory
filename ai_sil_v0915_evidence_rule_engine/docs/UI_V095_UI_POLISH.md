# UI v0.9.5 — Native Win32 Visual Polish

v0.9.5 freezes the v0.9.4 information architecture and starts the visual-polish pass.

The purpose is not to hide engineering operations or redesign the workflow. The same engineering resources, manual controls, TestPlan actions, QEMU controls, matrix, evidence and consoles remain available.

The UI layer now adds a consistent visual system:

- page background: soft neutral gray
- cards: white rounded surfaces
- primary: blue
- success: green
- warning/extendable: amber
- danger: red
- sidebar: deep navy
- console: dark terminal surface

Buttons are owner-drawn so the primary test action is visually distinct from engineering secondary controls. Stop uses a danger treatment. Plan/Console tabs expose active state. Pipeline stages also use semantic state backgrounds.

The implementation remains native Go/Win32. It deliberately avoids changing the existing AI Planner, Capability Router/Builder, Build Manager, QEMU control, MSH executor, Rule Engine and report paths.
