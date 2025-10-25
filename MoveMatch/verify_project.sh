#!/bin/bash
#
# Move Match - Project Verification Script
# Checks that all required files are present before building
#

echo "🔍 Move Match - Project Verification"
echo "======================================"
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
    else
        echo -e "${RED}❌${NC} $1 - MISSING"
        ((ERRORS++))
    fi
}

# Function to check directory exists
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅${NC} $1/"
    else
        echo -e "${RED}❌${NC} $1/ - MISSING"
        ((ERRORS++))
    fi
}

# Function to warn about missing optional files
warn_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅${NC} $1"
    else
        echo -e "${YELLOW}⚠️ ${NC} $1 - OPTIONAL (should create before building)"
        ((WARNINGS++))
    fi
}

echo "📦 Core Configuration Files:"
check_file "Package.swift"
check_file "MoveMatch/Info.plist"
check_file ".gitignore"
warn_file "GoogleService-Info.plist"

echo ""
echo "📱 Swift Source Files:"

echo ""
echo "  Models:"
check_file "MoveMatch/Models/GameModels.swift"

echo ""
echo "  Core - ARKit:"
check_file "MoveMatch/Core/ARKit/BodyTrackingManager.swift"

echo ""
echo "  Core - Audio:"
check_file "MoveMatch/Core/Audio/AudioAnalyzer.swift"

echo ""
echo "  Core - Puzzle:"
check_file "MoveMatch/Core/Puzzle/PuzzleGenerator.swift"

echo ""
echo "  Core - Game:"
check_file "MoveMatch/Core/Game/GameEngine.swift"

echo ""
echo "  App:"
check_file "MoveMatch/App/MoveMatchApp.swift"

echo ""
echo "  Features - Views:"
check_file "MoveMatch/Features/WelcomeView.swift"
check_file "MoveMatch/Features/MainMenu/MainMenuView.swift"
check_file "MoveMatch/Features/SongSelection/SongSelectionView.swift"
check_file "MoveMatch/Features/Gameplay/GameplayView.swift"
check_file "MoveMatch/Features/Results/ResultsView.swift"
check_file "MoveMatch/Features/Profile/ProfileView.swift"
check_file "MoveMatch/Features/Shop/ShopView.swift"

echo ""
echo "  Services - Firebase:"
check_file "MoveMatch/Services/Firebase/FirebaseManager.swift"

echo ""
echo "  Services - Monetization:"
check_file "MoveMatch/Services/Monetization/AdManager.swift"
check_file "MoveMatch/Services/Monetization/IAPManager.swift"

echo ""
echo "  Services - Progression:"
check_file "MoveMatch/Services/ProgressionManager.swift"

echo ""
echo "📚 Documentation:"
check_file "README.md"
check_file "BUILD_INSTRUCTIONS.md"
check_file "DEPLOYMENT_GUIDE.md"

echo ""
echo "======================================"
echo ""

# Count Swift files
SWIFT_FILES=$(find MoveMatch -name "*.swift" 2>/dev/null | wc -l)
echo "📊 Statistics:"
echo "   Swift files: $SWIFT_FILES"

# Count lines of code (excluding blank lines and comments)
if command -v cloc &> /dev/null; then
    echo ""
    echo "📏 Lines of Code (via cloc):"
    cloc MoveMatch --quiet --include-lang=Swift
else
    TOTAL_LINES=$(find MoveMatch -name "*.swift" -exec cat {} \; 2>/dev/null | wc -l)
    echo "   Total lines (rough): ~$TOTAL_LINES"
    echo "   (Install 'cloc' for accurate count: brew install cloc)"
fi

echo ""
echo "======================================"
echo ""

# Final verdict
if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 PROJECT READY!${NC}"
        echo ""
        echo "All required files are present."
        echo "Next steps:"
        echo "  1. Create Firebase project and download GoogleService-Info.plist"
        echo "  2. Open Package.swift in Xcode"
        echo "  3. Configure signing & capabilities"
        echo "  4. Build and run on your iPhone!"
        exit 0
    else
        echo -e "${YELLOW}⚠️  PROJECT MOSTLY READY${NC}"
        echo ""
        echo "Core files present but $WARNINGS optional file(s) missing."
        echo "You should create GoogleService-Info.plist before building."
        exit 0
    fi
else
    echo -e "${RED}❌ PROJECT INCOMPLETE${NC}"
    echo ""
    echo "Found $ERRORS missing required file(s)."
    echo "Please ensure all files are present before building."
    exit 1
fi
