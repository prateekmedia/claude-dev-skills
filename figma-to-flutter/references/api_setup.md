# Figma API Server Setup

## Prerequisites Check

Before starting the workflow, verify the Figma API server is running at `http://localhost:3001`.

Test with:
```bash
curl -s http://localhost:3001/health || echo "Server not running"
```

## Initial Setup (One-Time)

If the server is not running, set it up:

### 1. Clone Repository
```bash
mkdir -p ~/Documents
git clone https://github.com/prateekmedia/FigmaToCode-RestApi ~/Documents/figma-api
```

### 2. Launch Server
```bash
cd ~/Documents/figma-api
# Follow the README instructions to:
# - Install dependencies
# - Set up FIGMA_TOKEN in .env
# - Start the server on port 3001
```

## API Endpoints

### Screenshot API

Captures Figma design screenshots.

**Endpoint**: `POST http://localhost:3001/api/screenshot`

**Request Body**:
```json
{
  "url": "$FIGMA_URL",
  "format": "png",
  "scale": 2,
  "saveToFile": true,
  "directory": ".ui-workspace/$FEATURE/figma_screenshots"
}
```

**Parameters**:
- `url`: Full Figma design URL
- `format`: Output format (png/svg/jpg)
- `scale`: Screenshot scale (0.5-4, recommend 2)
- `saveToFile`: Always true for this workflow
- `directory`: Relative path from git repo root

### Convert API

Converts Figma designs to Flutter code and exports assets.

**Endpoint**: `POST http://localhost:3001/api/convert`

**Request Body (Default - All Scales)**:
```json
{
  "url": "$FIGMA_URL",
  "settings": {
    "framework": "Flutter"
  },
  "exportImages": true,
  "exportImagesOptions": {
    "scales": ["1x", "2x", "3x", "4x"],
    "directory": ".ui-workspace/$FEATURE/figma_images"
  },
  "output": {
    "saveToFile": true,
    "directory": ".ui-workspace/$FEATURE/figma_code"
  }
}
```

**Request Body (Customized Scales)**:
```json
{
  "url": "$FIGMA_URL",
  "settings": {
    "framework": "Flutter"
  },
  "exportImages": true,
  "exportImagesOptions": {
    "scales": ["2x", "3x"],
    "directory": ".ui-workspace/$FEATURE/figma_images"
  },
  "output": {
    "saveToFile": true,
    "directory": ".ui-workspace/$FEATURE/figma_code"
  }
}
```

**Parameters**:
- `settings.framework`: Must be "Flutter"
- `exportImages`: Always true to get asset images
- `exportImagesOptions.scales`: Array of scales to export (e.g., `["1x", "2x", "3x", "4x"]` or subset like `["3x"]`)
- `exportImagesOptions.directory`: Where to save exported assets
- `output.directory`: Where to save generated Flutter code

**Customizing Scales**:

Before calling this API, analyze the app's asset structure to determine which scales are needed:

1. **Multi-directory structure** (e.g., `assets/`, `assets/2x/`, `assets/3x/`):
   - Check which scale directories exist
   - Request only those scales: `["1x", "2x", "3x"]`

2. **Single directory with scale parameter** (e.g., `Image.asset('img.png', scale: 4)`):
   - Search codebase for `Image.asset` calls with scale parameters
   - Request only the scale value used: `["4x"]` or `["3x"]`

3. **No standard or new project**:
   - Default to 3x scale: `["3x"]`

**Benefits of Customizing Scales**:
- Reduces download size and time
- Avoids cluttering workspace with unused resolutions
- Matches app's existing conventions

**Output Structure**:
- Code files saved to `figma_code/`
- Assets exported to `figma_images/` with subdirectories based on requested scales:
  - `1x/` - Base resolution assets (if requested)
  - `2x/` - 2x resolution assets (if requested)
  - `3x/` - 3x resolution assets (if requested)
  - `4x/` - 4x resolution assets (if requested)

### Image Export API (Optional)

For re-exporting specific images or different scales.

**Endpoint**: `POST http://localhost:3001/api/export-images`

**Request Body**:
```json
{
  "url": "$FIGMA_URL",
  "exportOptions": {
    "scales": ["1x", "2x", "3x", "4x"],
    "directory": ".ui-workspace/$FEATURE/figma_images"
  }
}
```

## Image Naming Convention

Exported images use the format: `{nodeId}_{originalName}` to prevent conflicts.

Example: `123:456_user_avatar.png`

## Troubleshooting

### Server Not Responding
- Check if process is running: `lsof -i :3001`
- Review server logs in the figma-api directory
- Verify FIGMA_TOKEN is set in .env

### Authentication Errors
- Ensure FIGMA_TOKEN is valid
- Check token has access to the Figma file
- Verify file URL is correct and accessible

### Export Failures
- Confirm directory paths are relative to git repo root
- Ensure sufficient disk space
- Check file permissions for target directories
