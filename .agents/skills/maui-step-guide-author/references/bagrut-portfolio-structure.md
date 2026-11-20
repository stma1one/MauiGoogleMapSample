# Ministry of Education Project Portfolio Structure (תיק פרויקט — סמל 883589)

Use this reference when compiling or extending the student's formal Project Portfolio (`Learning/MAUI-Learning-Book.md`, `Learning/Guides/*.md`, and the compiled PDF book).

## Formatting & Layout Standards (משקל מראה התיק: 15% מציון התיק)

- **Language & Tense:** Write in Hebrew (present or past tense — לשון הווה/עבר), keeping C#, XAML, SQL, and .NET identifiers in English.
- **Typography:** Body paragraphs use clean readable typography (David / Arial / Assistant up to 12pt in Word/Docs/PDF), with distinct headings (`H1`, `H2`, `H3`) for automatic Table of Contents generation.
- **Header & Footer:** Every page includes a header with the **Student Name / Project Title** and a footer with the **Page Number**.
- **Cover Page (8 Mandatory Fields):**
  1. School Logo (לוגו בית הספר)
  2. School Name (שם בית הספר + סמל מוסד)
  3. Project Title (שם העבודה)
  4. Student Name (שם התלמיד/ה)
  5. Student ID (ת.ז. התלמיד/ה)
  6. Mentor Name (שם המנחה)
  7. Track Name (שם החלופה: תכנות טלפונים חכמים — 883589, 5 יח"ל)
  8. Submission Date (תאריך ההגשה)

---

## Mandatory 8 Chapters of the Project Portfolio (משקל תוכן התיק: 85% מציון התיק)

### 1. טבלת תכולות הפרויקט (Project Contents & Rubric Table)
- Embed the completed table from `Learning/Bagrut-Compliance.md` mapping every implemented requirement (Thresholds 1–4, the chosen AI path in Section 5, Section 6 topics, Section 7 database, and Section 8/9/10 advanced topics) to its concrete classes in the project.

### 2. מבוא ותיאור תחום הידע (Introduction & Domain Description — 10%)
- **הרקע לפרויקט:** שם הפרויקט, תיאור קצר, קהל היעד, והסיבות לבחירת הנושא (לפחות עמוד מתומצת).
- **תהליך המחקר:** מחקר על תחום הידע, סקירת אפליקציות קיימות בשוק, והסבר על כל טכנולוגיה חדשה שאינה בתוכנית הלימודים הבסיסית.
- **אתגרים מרכזיים וחידושים:** בעיות שהתעוררו בפיתוח, הצורך שהפרויקט פותר, פתרונות שנבחנו, והתאמות עיצוביות/טכנולוגיות.
- **תיאור תחום הידע (פרק מילולי):** אובייקטים נחוצים, סוגי נתונים, ייצוג המידע (רשימות, טבלאות, מבני נתונים וקשרים ביניהם + נימוק הבחירה), ותיאור פעולות על המידע (קריאה, הוספה, עדכון, מחיקה).

### 3. מבנה / ארכיטקטורה של הפרויקט (Architecture & Screen Design — 15%)
*(חשוב: בפרק זה אין להציג קוד של המחלקות!)*
- **חלק א' — תכנון ותיעוד מסכי הפרויקט:**
  - תיאור מסך הפתיחה וכיצד הוא משמש כנקודת ניווט (`AppShell`).
  - עבור כל מסך: שם ותפקיד המסך, תיאור המידע המוצג והפעולות האפשריות, תמונת מסך (או מודל HTML מתויג), והסבר על תפקיד כל פקד תצוגה (כפתור, תיבת טקסט, רשימה).
  - **תרשים זרימת מסכים (`Screen Flow Diagram`):** נוצר אוטומטית באמצעות `Scripts/Generate-Architecture-Diagrams.py` ונשמר ב-`Learning/Diagrams/Screen-Flow.mmd` וב-`Learning/Diagrams/Architecture-Diagram-Prompts.md`.
- **חלק ב' — תיאור מחלקות הפרויקט (`UML Class Diagram`):**
  - תרשים UML של המחלקות והקשרים ביניהן (ירושה, הכלה, הזרקת תלויות), המופק אוטומטית ב-`Learning/Diagrams/Architecture-UML.mmd`.

### 4. מימוש הפרויקט ובסיס הנתונים (Implementation & Database — 35%: 25% מימוש + 10% מסד נתונים)
- **הפרדה ברורה בין חלקי הפרויקט:** חלק לוגי (`Models`, `Services`), חלק גרפי (`Views`, `Converters`, `Drawables`), וניהול/תיאום (`ViewModels`, `MauiProgram`).
- **עבור כל מחלקה בפרויקט (כולל קובצי תצורה):**
  1. שם המחלקה.
  2. תפקיד המחלקה.
  3. הסבר כל תכונות המחלקה (כולל תכונות סטטיות): תחום הכרה (`public`/`private`) ותפקיד/שימוש.
  4. הסבר קצר של הפעולות במחלקה (ללא `get`/`set` טריוויאליים). את הפעולות הלוגיות העיקריות יש להסביר בהרחבה, לצרף את קטע הקוד הרלוונטי, ובתהליך סדרתי לצרף תרשים זרימה.
- **בסיס נתונים (10%):** סקירת בסיס הנתונים שנבחר (`SQLite` או מסד מרוחק מסונכרן), ארגון הטבלאות/האוספים, דוגמאות למידע כפי שנשמר בטבלה, והסבר על פעולות הקריאה והכתיבה.

### 5. מדריך למשתמש (User Manual — 10%)
- דרישות מערכת והוראות התקנה בסביבת העבודה.
- גרסאות וסוגי מכשירים / אמולטורים שעליהם נבדק הפרויקט.
- תיאור אופן הפעולה של האפליקציה בשפה ידידותית למשתמש (ללא כניסה למימוש טכני).
- פירוט הודעות למשתמש (`DisplayAlertAsync` וכד') וציון מגבלות או אילוצים בשדות הקלט (מספר תווים, גודל קובץ/תמונה, פורמט אימייל/טלפון).

### 6. סיכום אישי / רפלקציה (Personal Reflection — 5%)
*(היקף נדרש: חצי עמוד עד עמוד שלם ומעמיק, לא שורות תודה כלליות)*
- תיאור תהליך העבודה, ההצלחות, האתגרים, הקשיים ודרכי הפתרון.
- תהליך הלמידה העצמאית ותכולות חדשות שנלמדו.
- כלים מקצועיים שנלקחים להמשך הדרך.
- תובנות מהתהליך (התייעצות עם מומחים, שיתוף מידע, למידת עמיתים).
- בראייה לאחור: מה היית מיישם אחרת.
- שיפורים והרחבות עתידיות לו היו משאבים נוספים, ושאלות חקר עצמי.

### 7. ביבליוגרפיה ושקיפות קוד AI (Bibliography & AI Attribution — חלק מ-10%)
- רשימת מקורות המידע לפי כללי ה-**APA** מתוך `Learning/AI-And-External-Code-Attribution.md`.
- שילוב טבלת שקיפות קוד ה-AI והמקורות החיצוניים מתוך `Learning/AI-And-External-Code-Attribution.md` (ללא ליכלוך קובצי הקוד עצמם בהערות ייחוס ל-AI).

### 8. נספחים (Appendices — חלק מ-10%)
- תדפיס **טקסט מסודר** של קוד המחלקות של הפרויקט (לא צילומי מסך של קוד!) הכולל הערות תיעוד מקצועיות (XML Docs) בכל המקומות הרלוונטיים.

## שילוב צילומי מסך אמיתיים מ-MAUI DevFlow בתיק הפרויקט (883589)

- **צילומי ריצה אמיתיים כאשר `MAUI DevFlow` מותקן ועובד (`Learning/Images/<ScreenName>-live.png`)**: כאשר `Microsoft.Maui.DevFlow.Agent` מותקן ופועל במצב `Debug` על פלטפורמת היעד (פרויקטי `net10.0` / `net11.0`), הסוכן מצלם את המסכים הרצים בפועל מתוך האמולטור/המכשיר ושומר אותם תחת `Learning/Images/`.
- **שימוש בתיק הפרויקט (883589)**:
  - **פרק 3 (תכנון מסכים וזרימת מסכים)**: שלבו את צילומי המסך מ-`Learning/Images/` לצד תרשים זרימת המסכים (`Learning/Diagrams/Screen-Flow.svg`).
  - **פרק 5 (מדריך למשתמש)**: השתמשו בצילומי המסך להדגמת תרחישי השימוש, מצבי הקלט והודעות השגיאה.
  - **מוקאפ HTML / צילומי אמולטור רגילים כגיבוי**: מאחר שתמיכת Android ו-Windows ב-`MAUI DevFlow` עדיין מסומנת "In progress" אצל Microsoft (ובפרויקטי `net9.0` או כאשר ההזרקה בוטלה עם `--skip-devflow`), קובצי `Learning/Mockups/<ScreenName>.html` (או צילומי מסך רגילים) משמשים כגיבוי תקני כאשר `MAUI DevFlow` אינו מותקן או אינו פעיל בסביבת הריצה.
