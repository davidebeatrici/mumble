# Copyright 2020 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

param([Parameter(Mandatory=$true)]$packageName,
	[Parameter(Mandatory=$true)]$version,
	[Parameter(Mandatory=$true)]$systemName
)

# requires WiX install and the env var
if(Test-Path $env:WIX) {
	$cultures = "cs-CZ",
		"da-DK",
		"en-US",
		"nl-NL",
		"fi-FI",
		"fr-FR",
		"de-DE",
		"el-GR",
		"it-IT",
		"ja-JP",
		"nb-NO",
		"pl-PL",
		"pt-PT",
		"ru-RU",
		"es-ES",
		"sv-SE",
		"tr-TR",
		"zh-CN",
		"zh-TW"

	$wixBinaryDir = $env:WIX + "bin"
	$installerName = "$packageName-$version-$systemName"

	if(-Not (Test-Path -Path ".\EmbedTransform.exe")) {
		Write-Host "Downloading EmbedTransform from FireGiant (WiX)..."

		try {
			Invoke-WebRequest https://www.firegiant.com/system/files/samples/EmbedTransform.zip -OutFile ".\EmbedTransform.zip"
		}

		catch {
			Write-Host "URL for FireGiant has been removed or is not available. Aborting..."
			exit 1
		}

		Write-Host "Extracting EmbedTransform archive..."

		try {
			Expand-Archive -Path ".\EmbedTransform.zip" -DestinationPath "."
		}

		catch {
			Write-Host "EmbedTransform archive missing or corrupt. Aborting..."
			exit 1
		}
	}

	# create final release msi file
	cpack -C Release -D CPACK_PACKAGE_FILE_NAME=$installerName-MUI -D CPACK_WIX_CULTURES=$PSCulture -B .\install

	foreach($culture in $cultures) {
		if(-Not ($PSCulture -eq $culture)) {
			Write-Host "Creating installer for $culture..."
			cpack -C Release -D CPACK_PACKAGE_FILE_NAME=$installerName-$culture -D CPACK_WIX_CULTURES=$culture -B .\install
			Write-Host "Creating language transform for $culture..."
			& $wixBinaryDir\torch.exe -p -t language install\$installerName-MUI.msi install\$installerName-$culture.msi -out install\$culture.mst
			Write-Host "Embedding transform for $culture..."
			& .\EmbedTransform.exe install\$installerName-MUI.msi install\$culture.mst
		}
	}

	# generate checksum file
	Write-Host "Generating $installerName checksum (SHA1)..."
	$checksum = Get-FileHash install\$installerName-MUI.msi -Algorithm SHA1 | Select-Object -ExpandProperty Hash
	$chksumOutput = "$installerName - $checksum"
	Write-Host "Creating checksum file..."
	Out-File -InputObject $chksumOutput -FilePath install\$installerName-MUI.sha1
}

else {
	Write-Host "Error: WiX is not installed or not in the system PATH! Aborting..."
}
