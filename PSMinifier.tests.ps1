﻿#requires -Module Pester
describe 'PSMinifier' {
    it 'Makes scripts smaller' {
        $compressScriptBlock = Get-Command Compress-ScriptBlock
        $compressed = $compressScriptBlock |
            Compress-ScriptBlock -Anonymous
        if ($compressed.Length -gt $compressScriptBlock.ScriptBlock.ToString().Length) {
            throw "Minified length $($compressed.Length) exceeds input length $($compressScriptBlock.ScriptBlock.ToString().Length)"
        }
    }

    it 'Can -GZip them to make them even smaller' {
        $compressScriptBlock = Get-Command Compress-ScriptBlock
        $compressed = $compressScriptBlock |
            Compress-ScriptBlock -Anonymous
        $gzipped = $compressScriptBlock |
            Compress-ScriptBlock -GZip -Anonymous
        if ($gzipped.Length -gt $compressScriptBlock.ScriptBlock.ToString().Length) {
            throw "GZipped length $($gzipped.Length) exceeds input length $($compressScriptBlock.ScriptBlock.ToString().Length)"
        }

        if ($gzipped.Length -gt $compressed.Length) {
            throw "GZipped length $($gzipped.Length) exceeds minified length $($compressed.Length)"
        }
    }

    it 'Can shrink try catch blocks' {

        $originalScript = {
            try {
                thisMightThrowBecauseThereIsNoCommand | # this commend should go away.
                    thispipeline also uses     a lot of whitespace
            } catch [System.SystemException] {
                "Oh No! An Exception Occured" |
                    Out-String
            } finally {
                "FinallyGotSomethingDone" | Out-String
            }
        }
        $compresedScript = [Scriptblock]::Create((Compress-ScriptBlock -ScriptBlock $originalScript))
        "$compressedScript".Length |
            Should -BeLessThan "$originalScript".Length
        @(& $compresedScript) -join '' |
            Should -BeLike "*Oh*No!*An*Exception*Occured*FinallyGotSomethingDone*"
    }

    it 'Can compress a [hashtable]' {
        Compress-ScriptBlock -ScriptBlock {
            @{
                a = "b"
                c = "d"
                e = @{
                    f = "h"
                }
            }
        } | Should -Not -Match "\n"
    }

    it 'Can compress an ordered [hashtable]' {
        Compress-ScriptBlock -ScriptBlock {
            [Ordered]@{
                a = "b"
                c = "d"
                e = @{
                    f = "h"
                }
            }
        } | Should -Not -Match "\n"
    }

    it 'Can compress a using statement' {
        $compressed = Compress-ScriptBlock -ScriptBlock ([ScriptBlock]::Create(@"
using namespace System.Security.Cryptography
using namespace System.Windows.Forms
echo 1
echo 2
"@))
        $compressed | Should -Match "using"
        $compressed | Should -Not -Match "\n"

        Invoke-Expression $compressed | Select-Object -First 1 | Should -Be 1
    }
}