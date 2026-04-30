@{
    # Ergebnisstufe: nur Errors + Warnings, Information nicht
    Severity = @('Error', 'Warning')

    # Regeln, die fuer dieses Repo bewusst NICHT durchgesetzt werden
    ExcludeRules = @(
        # Demo-/Operational-Skripte nutzen Write-Host bewusst fuer farbige
        # Console-Ausgaben (kein Pipeline-Output gewuenscht)
        'PSAvoidUsingWriteHost',

        # ConfigMgr-Module-Stil: viele Cmdlets haben legitim plurale Nouns
        'PSUseSingularNouns',

        # Skript-scope-Variablen sind Absicht in den _common.ps1-Dateien
        'PSAvoidGlobalVars',

        # Wait-/Demo-Skripte haben oft ungenutzte Parameter (Schalter wie -ShowProperties)
        'PSReviewUnusedParameter',

        # Setup-Skripte sind interaktiv/operational, kein -WhatIf-Pflichtpfad
        'PSUseShouldProcessForStateChangingFunctions',

        # Wir nutzen ConvertTo-SecureString in der Doku, nie persistent in Skripten
        'PSAvoidUsingConvertToSecureStringWithPlainText',

        # Demo-Helfer rufen sich selbst per Dot-Sourcing auf
        'PSAvoidUsingPositionalParameters'
    )
}
