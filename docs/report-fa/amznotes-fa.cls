% amznotes-fa — amznotes adapted for Persian/RTL (XeLaTeX only)
% Based on amznotes by Alex M Zhang

\ProvidesClass{amznotes-fa}[2026/06/16 amznotes Persian RTL]
\NeedsTeXFormat{LaTeX2e}

\LoadClass[12pt]{report}

% Use manual newif to avoid kvoptions hyphen-in-name breakage
\newif\ifamzfa@code
\newif\ifamzfa@fastcompile

\DeclareOption{code}{\amzfa@codetrue}
\DeclareOption{fastcompile}{\amzfa@fastcompiletrue}
\ProcessOptions\relax

% ------------------------------------------------------------
% PACKAGES

\RequirePackage[margin=1in]{geometry}
\RequirePackage{fontspec}
\RequirePackage{unicode-math}
\RequirePackage[dvipsnames]{xcolor}
\RequirePackage{hyperref}
\RequirePackage{fancyhdr}
\RequirePackage{lastpage}
\RequirePackage{parskip}
\RequirePackage{setspace}
\RequirePackage[explicit]{titlesec}
\RequirePackage[most]{tcolorbox}
\RequirePackage{etoolbox}
\RequirePackage{multicol}
\RequirePackage{enumitem}
\RequirePackage{tabularx}
\RequirePackage{booktabs}

\ifamzfa@code
    \RequirePackage{minted}
    \tcbuselibrary{minted}
\fi

% xepersian must be the last package loaded
\RequirePackage{xepersian}

% ------------------------------------------------------------
% FONTS (must come after xepersian)

\settextfont[
    BoldFont={Vazirmatn},
    BoldFeatures={FakeBold=2},
]{Vazirmatn}

\setdigitfont{Vazirmatn}
\setmathfont{latinmodern-math.otf}
\setmonofont{Liberation Mono}

% Redefine the Latin font
\redeflatinfont\latinfont{Liberation Serif}

% ------------------------------------------------------------
% PAGE LAYOUT

\onehalfspacing
\renewcommand{\arraystretch}{1.25}

% ------------------------------------------------------------
% COLORS

\definecolor{amzchaptercolor}{HTML}{0984e3}
\definecolor{amzdfnboxcolor}{HTML}{0984e3}
\definecolor{amzexboxcolor}{HTML}{fdcb6e}
\definecolor{amzgenboxcolor}{HTML}{00b894}
\definecolor{amztecboxcolor}{HTML}{e17055}
\definecolor{amzcodeboxcolor}{HTML}{2d3436}
\definecolor{amznoteboxcolor}{HTML}{d63031}

% ------------------------------------------------------------
% HYPERREF

\hypersetup{
    colorlinks=false,
    linkbordercolor=black,
    urlbordercolor=blue,
    pdfborderstyle={/S/U/W 1}
}

% ------------------------------------------------------------
% CHAPTER STYLING

\ifamzfa@fastcompile\else

\titleformat{\chapter}[display]
{\normalfont\huge\bfseries}{}
{20pt}
{
    \begin{tcolorbox}[
        enhanced,
        left=23mm, right=25mm, top=2mm,
        spread sidewards, sharp corners,
        colback=amzchaptercolor, colframe=amzchaptercolor,
        boxrule=1mm,
        title=\thechapter,
        attach boxed title to top left={xshift=15mm, yshift=-4mm},
        boxed title style={size=small, colback=amzchaptercolor, colframe=white}
    ]
        \strut \textcolor{white}{#1}
    \end{tcolorbox}
}

\titleformat{name=\chapter,numberless}[display]
{\normalfont\huge\bfseries}{}
{20pt}
{
    \begin{tcolorbox}[
        enhanced, left=23mm, right=25mm, top=2mm,
        spread sidewards, sharp corners,
        colback=amzchaptercolor, colframe=amzchaptercolor,
        boxrule=1mm,
    ]
        \strut \textcolor{white}{#1}
    \end{tcolorbox}
}

\titlespacing*{\chapter}{0pt}{-40mm}{-10mm}

\fi

% ------------------------------------------------------------
% HEADERS

\ifamzfa@fastcompile\else

\pagestyle{fancy}
\lhead{\footnotesize\nouppercase{\rightmark}}
\rhead{\footnotesize\nouppercase{\leftmark}}
\cfoot{\thepage\ از \pageref{LastPage}}

\fancypagestyle{plain}{
    \renewcommand{\headrulewidth}{0pt}
    \fancyhead{}
    \cfoot[C]{\thepage\ از \pageref{LastPage}}
}

\fi

% ------------------------------------------------------------
% COLOR BOXES

\newcommand{\amzcolorboxtitlesep}{\ \raisebox{2.3pt}{\scalebox{0.5}{$\blacktriangleleft$}}}

\ifamzfa@fastcompile
\tcbset{
    amzdefaultstyle/.style={
        fonttitle=\strut\bfseries,
        separator sign=\amzcolorboxtitlesep,
        breakable
    },
    noteboxstyle/.style={breakable},
}
\else
\tcbset{
    amzdefaultstyle/.style={
        enhanced,
        drop fuzzy shadow,
        fonttitle=\strut\bfseries,
        boxrule=0pt,
        frame hidden,
        separator sign=\amzcolorboxtitlesep,
        breakable,
    },
    noteboxstyle/.style={
        enhanced,
        boxrule=0pt,
        frame hidden,
        borderline west={4pt}{0pt}{amznoteboxcolor},
        colback=amznoteboxcolor!7!white,
        sharp corners,
    },
    codeboxstyle/.style={
        overlay={
            \begin{tcbclipinterior}
            \fill[darkgray!20!white] (frame.south west)
                rectangle ([xshift=6mm]frame.north west);
            \end{tcbclipinterior}
        },
        skin=bicolor,
        collower=white,
        colbacklower=darkgray
    },
}
\fi

\renewcommand{\l@tcolorbox}{\@dottedtocline{1}{0pt}{3em}}
\setlength{\columnsep}{3em}

\newcommand{\amzindexbody}{}
\newcommand{\addindexentry}[2]{%
    \appto\amzindexbody{
        \iftoggle{#2}{
            \tcblistof[\section*]{#2}{#1}
        }{}
    }
}

\newcounter{amzboxcounter}
\NewDocumentCommand{\newamzbox}{m m m m O{}}{
    \newtcbtheorem[
        use counter=amzboxcounter,
        number within=section,
        list inside={#3}
    ]{tc#1}{#2}{
        amzdefaultstyle,
        frame style={fill=#4!85!black},
        interior style={fill=#4!5!white},
        segmentation style={solid,draw=#4!50!black,opacity=0.25,line width=1pt},
        #5
    }{#3}

    \providetoggle{#3}
    \settoggle{#3}{false}

    \newenvironment{#1}[2]{
        \global\settoggle{#3}{true}
        \begin{tc#1}{##1}{##2}
    }{\end{tc#1}}

    \newenvironment{#1*}[1]{
        \begin{tc#1*}{##1}
    }{\end{tc#1*}}

    \addindexentry{#2s}{#3}
}

\newamzbox{dfnbox}{تعریف}{dfn}{amzdfnboxcolor}
\newamzbox{exbox}{مثال}{ex}{amzexboxcolor}
\newamzbox{tecbox}{تکنیک}{tec}{amztecboxcolor}

\newtcolorbox{genbox}[1]{
    amzdefaultstyle,
    frame style={fill=amzgenboxcolor!85!black},
    interior style={fill=amzgenboxcolor!5!white},
    title={#1}
}
\newtcolorbox{notebox}{noteboxstyle}

\ifamzfa@code
    \renewcommand{\theFancyVerbLine}{\lr{\ttfamily\scriptsize\arabic{FancyVerbLine}}}
    \newamzbox{codebox}{قطعه کد}{code}{amzcodeboxcolor}[codeboxstyle]

    \newenvironment{amzcode}[2][]{
        \VerbatimEnvironment
        \begin{latin}%
        \begin{minted}[
            linenos, breaklines, autogobble, xleftmargin=3.75mm,
        ]{#2}}
    {\end{minted}\end{latin}}
\fi

% ------------------------------------------------------------
% TEXT MACROS

\newcommand{\dfntxt}[1]{\textit{\textbf{#1}}}
\newcommand{\latincode}[1]{\lr{\texttt{#1}}}
