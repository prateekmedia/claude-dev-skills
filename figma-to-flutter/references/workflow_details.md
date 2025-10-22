# Figma to Flutter Workflow Details

## Directory Structure

All workflow files are stored in `.ui-workspace/{FeatureName}/` at the git repository root:

```
.ui-workspace/{FeatureName}/
├── app_screenshots/      # Screenshots from running Flutter app
├── figma_screenshots/    # Design screenshots from Figma
├── figma_images/        # Exported assets (scales vary based on app needs)
│   ├── 1x/              # Only if requested
│   ├── 2x/              # Only if requested
│   ├── 3x/              # Only if requested
│   ├── 4x/              # Only if requested
│   └── mapping.json     # Asset mapping (figma → app assets)
├── figma_code/          # Generated Flutter code from Figma
└── flutter-run.log      # Debug logs (optional)
```

**Important**:
- Create `.ui-workspace/` in the git repo root
- Add `.ui-workspace/` to `.git/info/exclude` if not already present (should not be committed)
- Only download the asset scales your app actually uses (see Asset Management section)

## Implementation Phase

### Using Reference Code

The generated Figma code serves as a reference for:
- **Text styles**: Font families, sizes, weights, colors
- **Container dimensions**: Width, height, padding, margins
- **Colors**: Exact color values from design
- **Layout structure**: Widget hierarchy and positioning
- **Spacing**: Gaps, padding values

**Important**: Do not copy the generated code directly. Use it as a reference while writing proper Flutter code that follows app conventions.

### Asset Management

#### 1. Analyze Existing Asset Structure

Before downloading or copying assets, analyze the app's current asset organization to understand the scaling strategy.

**Check Directory Structure**:
```bash
# List asset directories
ls -la assets/
```

**Common Patterns**:

**Pattern A: Multi-directory approach**
```
assets/
assets/2x/
assets/3x/
assets/4x/
```
Each scale has its own directory. Flutter automatically picks the appropriate resolution.

**Pattern B: Single directory with scale parameter**
```
assets/
```
Single directory with explicit `scale` parameter in code:
```dart
Image.asset('assets/image.png', scale: 4)
```

**Pattern C: No standard structure**
New project or inconsistent structure. Need to establish conventions.

#### 2. Search for Scale Usage in Code

Identify how the app currently handles image scaling:

```bash
# Search for Image.asset calls with scale parameter
grep -r "Image\.asset.*scale:" lib/

# Examples you might find:
# Image.asset('assets/icon.png', scale: 4)
# Image.asset('assets/background.png', scale: 3)
```

**Analysis**:
- If you find `scale: 4` frequently → app uses 4x assets in single directory
- If you find `scale: 3` → app uses 3x assets
- If you find multiple values → mixed approach, need to understand context
- If you find no scale parameters → likely uses multi-directory approach

#### 3. Determine Required Scales

Based on analysis, decide which scales to download:

**Multi-directory structure**: Check which directories exist
```bash
# Example: Only 2x and 3x exist
ls -d assets/*/  # Shows: assets/2x/ assets/3x/
# Download only: ["2x", "3x"]
```

**Single directory with scale parameter**: Match the scale values used
```bash
# If code uses scale: 4 consistently
# Download only: ["4x"]
```

**No standard or new project**:
- Default to **3x scale** as a good balance
- Download only: ["3x"]

**Important**: Only download scales actually needed to avoid unnecessary files.

#### 4. Download Assets with Correct Scales

Modify the Convert API call to request only needed scales:

```bash
# Example: App uses only 2x and 3x
curl -X POST http://localhost:3001/api/convert \
  -H "Content-Type: application/json" \
  -d "{
    \"url\": \"$FIGMA_URL\",
    \"settings\": {\"framework\": \"Flutter\"},
    \"exportImages\": true,
    \"exportImagesOptions\": {
      \"scales\": [\"2x\", \"3x\"],
      \"directory\": \".ui-workspace/$FEATURE/figma_images\"
    },
    \"output\": {
      \"saveToFile\": true,
      \"directory\": \".ui-workspace/$FEATURE/figma_code\"
    }
  }"
```

#### 5. Identify Required Assets

Review the generated Figma code to identify which image assets are referenced in the design.

#### 6. Copy and Rename Assets

Copy assets from `.ui-workspace/$FEATURE/figma_images/` following the app's structure:

**Multi-directory structure**:
```bash
# Copy each scale to corresponding directory
cp .ui-workspace/Feed/figma_images/2x/123:456_user_avatar.png assets/2x/profile_avatar.png
cp .ui-workspace/Feed/figma_images/3x/123:456_user_avatar.png assets/3x/profile_avatar.png

# Usage in code (Flutter picks resolution automatically):
Image.asset('assets/2x/profile_avatar.png')
```

**Single directory with scale parameter (4x example)**:
```bash
# Copy only the required scale
cp .ui-workspace/Feed/figma_images/4x/123:456_user_avatar.png assets/profile_avatar.png

# Usage in code with explicit scale:
Image.asset('assets/profile_avatar.png', scale: 4)
```

**Single directory with scale parameter (3x example)**:
```bash
# Copy only 3x scale
cp .ui-workspace/Feed/figma_images/3x/123:456_background.png assets/background.png

# Usage in code:
Image.asset('assets/background.png', scale: 3)
```

**No standard structure (establishing 3x default)**:
```bash
# Use 3x as default
cp .ui-workspace/Feed/figma_images/3x/123:456_icon.png assets/icon.png

# Usage in code with explicit scale:
Image.asset('assets/icon.png', scale: 3)
```

**Renaming Guidelines**:
- Use snake_case
- Be specific and descriptive (e.g., `profile_avatar.png` not `image1.png`)
- Include context if needed (e.g., `feed_empty_state_illustration.png`)

#### 7. Maintain Asset Mapping

Create/update `.ui-workspace/$FEATURE/figma_images/mapping.json` to track renamed assets:

```json
{
  "123:456_user_avatar.png": "assets/profile_avatar.png",
  "789:012_background.png": "assets/background.png",
  "345:678_icon.png": "assets/feed_icon.png"
}
```

This mapping helps track which Figma assets correspond to which app assets for future reference.

#### 8. Update pubspec.yaml

Ensure assets are declared according to the app's structure.

**Multi-directory**:
```yaml
flutter:
  assets:
    - assets/
    - assets/2x/
    - assets/3x/
    # Add other scales if used
```

**Single directory**:
```yaml
flutter:
  assets:
    - assets/
```

#### 9. Verify Asset Usage

After copying assets, verify they're being used correctly in the code:

**Multi-directory**: Check that Flutter is finding the right resolution
```dart
// Flutter automatically selects from assets/, assets/2x/, assets/3x/
Image.asset('assets/2x/profile_avatar.png')
```

**Single directory with scale**: Ensure scale parameter matches downloaded resolution
```dart
// If you downloaded 4x, use scale: 4
Image.asset('assets/profile_avatar.png', scale: 4)

// If you downloaded 3x, use scale: 3
Image.asset('assets/background.png', scale: 3)
```

## Testing Phase

### Golden Tests

Golden tests capture widget screenshots for visual regression testing.

#### Test Structure

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('UserProfile screen golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(), // Your implementation
      ),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/user_profile.png'),
    );
  });
}
```

#### Important Considerations

1. **Device Size**: Match the Figma design dimensions
   ```dart
   await tester.binding.setSurfaceSize(Size(375, 812)); // iPhone X
   ```

2. **Rendering**: Ensure all content is visible
   - Images must load (use fake image data in tests)
   - Text should not be obscured
   - No overflow errors

3. **Scrollable Content**:
   - **Finite height**: Capture complete scrollable area if possible
   - **Infinite/long lists**: Capture multiple scroll states for comparison
   ```dart
   // Capture initial state
   await expectLater(find.byType(MaterialApp), matchesGoldenFile('screen_top.png'));

   // Scroll and capture
   await tester.drag(find.byType(ListView), Offset(0, -300));
   await tester.pumpAndSettle();
   await expectLater(find.byType(MaterialApp), matchesGoldenFile('screen_scrolled.png'));
   ```

#### Running Golden Tests

```bash
# Generate golden files
flutter test --update-goldens

# Run tests against golden files
flutter test
```

### App Screenshots

Capture screenshots from the running app for visual comparison.

#### iOS Simulator
```bash
xcrun simctl io booted screenshot .ui-workspace/$FEATURE/app_screenshots/ss_$(date +%Y-%m-%d_%H-%M-%S)_$description.png
```

#### Android Emulator
```bash
adb shell screencap -p > .ui-workspace/$FEATURE/app_screenshots/ss_$(date +%Y-%m-%d_%H-%M-%S)_$description.png
```

#### Real iOS Device
```bash
~/Documents/scripts/ios_screenshot.sh .ui-workspace/$FEATURE/app_screenshots/ss_$(date +%Y-%m-%d_%H-%M-%S)_$description.png
```

**Naming Convention**:
- Prefix: `ss_`
- Timestamp: `$(date +%Y-%m-%d_%H-%M-%S)`
- Description: Brief description of what's captured (e.g., `Feed_View`, `Profile_Edit`)

## Comparison & Iteration

### Visual Comparison Process

1. **Open Side-by-Side**:
   - Figma screenshot: `.ui-workspace/$FEATURE/figma_screenshots/`
   - App screenshot: `.ui-workspace/$FEATURE/app_screenshots/`

2. **Check for Differences**:
   - Layout positioning
   - Text sizes and weights
   - Colors (exact match)
   - Spacing (padding, margins)
   - Asset rendering
   - Shadows and borders
   - Border radius values

3. **Document Issues**: Note specific differences to fix

4. **Implement Fixes**: Update Flutter code based on identified issues

5. **Retest**: Take new app screenshots and compare again

6. **Repeat**: Continue until app screenshots match Figma screenshots exactly

### Common Issues

**Layout Problems**:
- Incorrect constraints (Expanded, Flexible usage)
- Wrong alignment values
- Missing or excessive padding

**Text Rendering**:
- Font family mismatch
- Wrong font weight
- Incorrect font size
- Text color differences
- Line height issues

**Asset Issues**:
- Wrong asset resolution
- Incorrect asset path
- Asset scaling problems
- Missing assets

**Color Mismatches**:
- Hex color typos
- Opacity values incorrect
- Wrong color references

**Spacing Issues**:
- Padding values don't match design
- Margin inconsistencies
- Gap sizes incorrect
- Container dimensions wrong

### Iteration Strategy

1. **Fix highest-impact differences first** (layout, major positioning)
2. **Then address styling** (colors, fonts, sizes)
3. **Finally tune details** (shadows, borders, spacing fine-tuning)
4. **Test each round of fixes** before moving to next category
5. **Keep comparing** until pixel-perfect match achieved

## Debug Logs (Optional)

If debugging Flutter app issues during workflow:

**Global logs**: `.special/logs.txt`
**Feature-specific logs**: `.special/{FeatureName}/logs.txt`

Contains output from `flutter run` commands for diagnosing errors.
