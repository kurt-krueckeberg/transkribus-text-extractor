<?php
declare(strict_types=1);

function processXmlDirectory(string $inputDir, string $outputDir): void
{
    if (!is_dir($inputDir)) {

        throw new RuntimeException("Input directory not found: $inputDir");
    }

    if (!is_dir($outputDir) && !mkdir($outputDir, 0777, true) && !is_dir($outputDir)) {

        throw new RuntimeException("Failed to create output directory: $outputDir");
    }

    $files = glob($inputDir . DIRECTORY_SEPARATOR . '*.xml');

    if ($files === false) {

        throw new RuntimeException("Failed to read XML files from: $inputDir");
    }

    foreach ($files as $filePath) {

        $text = extractTextFromXml($filePath);

        $baseName = pathinfo($filePath, PATHINFO_FILENAME);

        $outputFile = $outputDir . DIRECTORY_SEPARATOR . $baseName . '.txt';

        file_put_contents($outputFile, $text);
    }
}

function extractTextFromXml(string $filePath): string
{
    libxml_use_internal_errors(true);

    $xml = simplexml_load_file($filePath);

    if ($xml === false) {

        $errors = libxml_get_errors();

        libxml_clear_errors();

        throw new RuntimeException("Failed to load XML file: $filePath");
    }

    // Register default namespace if present (PAGE XML usually has one)
    $namespaces = $xml->getNamespaces(true);

    if (isset($namespaces[''])) {

        $xml->registerXPathNamespace('ns', $namespaces['']);

        $lines = $xml->xpath('//ns:TextLine/ns:TextEquiv/ns:Unicode');

    } else {

        $lines = $xml->xpath('//TextLine/TextEquiv/Unicode');
    }

    if ($lines === false) {

        throw new RuntimeException("XPath query failed on: $filePath");
    }

    $textLines = array_map(static fn($line) => trim((string)$line), $lines);

    return implode(PHP_EOL, $textLines);
}

// ---------- USAGE ----------

$inputDirectory = __DIR__ . '/xml_input';    // Change to your input path

$outputDirectory = __DIR__ . '/text_output'; // Change to your output path

try {

    processXmlDirectory($inputDirectory, $outputDirectory);

    echo "Text files created successfully in: $outputDirectory" . PHP_EOL;

} catch (Throwable $e) {

    echo 'Error: ' . $e->getMessage() . PHP_EOL;
}
