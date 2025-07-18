# Project Structure

## Current Organization
```
SpaceTycoon/
├── .git/           # Git version control
├── .kiro/          # Kiro AI assistant configuration
│   └── steering/   # AI guidance documents
├── README.md       # Project overview
```

## Recommended Future Structure
As the project develops, consider organizing code using these patterns:

### For Game Development
```
SpaceTycoon/
├── src/            # Source code
│   ├── core/       # Core game systems
│   ├── entities/   # Game objects (ships, stations, etc.)
│   ├── systems/    # Game logic systems
│   ├── ui/         # User interface components
│   └── utils/      # Utility functions
├── assets/         # Game assets
│   ├── sprites/    # 2D graphics
│   ├── models/     # 3D models
│   ├── audio/      # Sound effects and music
│   └── data/       # Game data files
├── tests/          # Unit and integration tests
├── docs/           # Documentation
└── build/          # Build output (gitignored)
```

## Naming Conventions
- Use PascalCase for classes and types
- Use camelCase for variables and functions
- Use kebab-case for file names where appropriate
- Use descriptive names that reflect space/tycoon theme

## File Organization Principles
- Group related functionality together
- Separate game logic from presentation
- Keep configuration and data files organized
- Maintain clear separation between source and build artifacts

## Future Considerations
- Add appropriate .gitignore for chosen technology stack
- Include build and deployment scripts
- Add documentation for setup and development workflow