#!/usr/bin/env bash
set -euo pipefail

TITLE="${1:-}"
WHAT_CHANGED="${2:-}"
WHY="${3:-}"
CONCEPT="${4:-}"
BATON_STAGE="${5:-CODE_LEARNING_REVIEWER}"
OWNERSHIP_SPLIT="${6:-Student implemented core logic; Agent scaffolded structure}"
VERIFICATION="${7:-dotnet build; dotnet test}"
MICROSOFT_LEARN="${8:-}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEARNING_DIR="$ROOT/Learning"
BOOK="$LEARNING_DIR/MAUI-Learning-Book.md"

mkdir -p "$LEARNING_DIR"

if [ ! -f "$BOOK" ]; then
    cat << 'EOF' > "$BOOK"
# MAUI Learning Book

זהו ספר הלמידה המתעדכן (Append-only) של הפרויקט.
כל ההסברים נכתבים בעברית תוך שמירה על מזהי קוד (C#, XAML, .NET) באנגלית.

EOF
fi

LESSON_COUNT=$(grep -c -E "^# (שיעור|Lesson) " "$BOOK" 2>/dev/null || true)
NUMBER=$((LESSON_COUNT + 1))
DATE=$(date "+%Y-%m-%d %H:%M")

cat << EOF >> "$BOOK"

# שיעור $NUMBER – $TITLE

_תאריך: $DATE | שלב Baton: \`$BATON_STAGE\`_

## חלוקת אחריות (Ownership Split)
$OWNERSHIP_SPLIT

## מה השתנה בקוד?
$WHAT_CHANGED

## למה בחרנו בארכיטקטורה הזו?
$WHY

## מושג ה-.NET MAUI / C# שנלמד
$CONCEPT

## כיצד לאמת (Verification)

\`\`\`text
$VERIFICATION
\`\`\`

## תיעוד רשמי לקריאה נוספת (Microsoft Learn)
$MICROSOFT_LEARN

## שאלות בדיקה עצמית לתלמיד

1. האם אתה יכול להסביר במילים שלך את זרימת הנתונים בין השכבות ללא קריאת הקוד?
2. איזו שכבה אחראית על ה-State ואיזו שכבה אחראית על הלוגיקה או שמירת הנתונים?

EOF

echo -e "\033[0;32mשיעור למידה $NUMBER נוסף בהצלחה אל MAUI-Learning-Book.md.\033[0m"
