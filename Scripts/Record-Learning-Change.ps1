param(
    [Parameter(Mandatory = $true)]
    [string]$Title,
    [Parameter(Mandatory = $true)]
    [string]$WhatChanged,
    [Parameter(Mandatory = $true)]
    [string]$Why,
    [Parameter(Mandatory = $true)]
    [string]$Concept,
    [string]$BatonStage = "CODE_LEARNING_REVIEWER",
    [string]$OwnershipSplit = "Student implemented core logic; Agent scaffolded structure",
    [string]$Verification = "dotnet build; dotnet test",
    [string]$MicrosoftLearn = ""
)

$root = Split-Path -Parent $PSScriptRoot
$learningDir = Join-Path $root "Learning"
$book = Join-Path $learningDir "MAUI-Learning-Book.md"

New-Item -ItemType Directory -Path $learningDir -Force | Out-Null

if (-not (Test-Path $book)) {
@"
# MAUI Learning Book

זהו ספר הלמידה המתעדכן (Append-only) של הפרויקט.
כל ההסברים נכתבים בעברית תוך שמירה על מזהי קוד (C#, XAML, .NET) באנגלית.

"@ | Set-Content $book -Encoding UTF8
}

$existing = Get-Content $book -Raw
$lessonCount = ([regex]::Matches($existing, '(?m)^# שיעור \d+|^# Lesson \d+')).Count
$number = $lessonCount + 1
$date = Get-Date -Format "yyyy-MM-dd HH:mm"

@"

# שיעור $number – $Title

_תאריך: $date | שלב Baton: `$BatonStage`_

## חלוקת אחריות (Ownership Split)
$OwnershipSplit

## מה השתנה בקוד?
$WhatChanged

## למה בחרנו בארכיטקטורה הזו?
$Why

## מושג ה-.NET MAUI / C# שנלמד
$Concept

## כיצד לאמת (Verification)
```text
$Verification
```

## תיעוד רשמי לקריאה נוספת (Microsoft Learn)
$MicrosoftLearn

## שאלות בדיקה עצמית לתלמיד

1. האם אתה יכול להסביר במילים שלך את זרימת הנתונים בין השכבות ללא קריאת הקוד?
2. איזו שכבה אחראית על ה-State ואיזו שכבה אחראית על הלוגיקה או שמירת הנתונים?
"@ | Add-Content $book -Encoding UTF8

Write-Host "שיעור למידה $number נוסף בהצלחה אל MAUI-Learning-Book.md." -ForegroundColor Green
