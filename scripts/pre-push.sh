#!/usr/bin/env bash

echo "⚡ Executing pre-push hook..."

SAIL="./vendor/bin/sail"

# Load variables from .env
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

# If you want to skip the checks use "SKIP_PRE_PUSH=true" in your .env
if [ "$SKIP_PRE_PUSH" = "true" ]; then
    echo "ℹ️ SKIP_PRE_PUSH=true detected. Checks skipped. Continuing with push..."
    exit 0
fi

# PHP lint
echo "🧹 Running Duster..."

if ! "$SAIL" php ./vendor/bin/duster lint; then
    echo "❌ Duster failed. Please run './vendor/bin/sail php ./vendor/bin/duster fix' before pushing."
    exit 1
fi

echo "✅ Duster passed."

# Frontend checks
if [ -f "package.json" ]; then
    echo "🔗 Generating Wayfinder routes..."

    if ! "$SAIL" artisan wayfinder:generate --with-form --no-interaction; then
        echo "❌ Wayfinder route generation failed. Run './vendor/bin/sail artisan wayfinder:generate --with-form --no-interaction' to inspect the error."
        exit 1
    fi

    echo "🎨 Running frontend format and lint checks..."

    if ! "$SAIL" npm run check; then
        echo "❌ Frontend check failed. Please run './vendor/bin/sail npm run check:fix' and resolve remaining issues before pushing."
        exit 1
    fi

    echo "🔎 Running frontend type check..."

    if ! "$SAIL" npm run types:check; then
        echo "❌ Frontend type check failed. Please fix the reported issues before pushing."
        exit 1
    fi

    echo "🏗️ Building frontend assets..."

    if ! "$SAIL" npm run build; then
        echo "❌ Frontend build failed. Please fix the build errors before pushing."
        exit 1
    fi

    echo "✅ Frontend checks passed."
else
    echo "ℹ️ No package.json found. Skipping frontend checks."
fi

# Pest tests
echo "🧪 Running Pest tests..."

if ! "$SAIL" test --parallel; then
    echo "❌ Pest tests failed. Please fix the failing tests before pushing."
    exit 1
fi

echo "✅ Pest tests passed."
echo "✅ All checks passed. Push allowed."

exit 0
