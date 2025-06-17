#!/usr/bin/env php
<?php
declare(strict_types=1);

class TextExtractor {

    function extractTextFromXml(string $filePath): array
    {
        $xml = simplexml_load_file($filePath);
    
        if ($xml === false) {
    
            $errors = libxml_get_errors();
    
            libxml_clear_errors();
    
            throw new RuntimeException("Failed to parse XML: $filePath");
        }
    
        // Handle default namespace (common in Transkribus PAGE XML)
        $namespaces = $xml->getNamespaces(true);
    
        if (isset($namespaces[''])) {
    
            $xml->registerXPathNamespace('ns', $namespaces['']);
    
            $lines = $xml->xpath('//ns:TextLine/ns:TextEquiv/ns:Unicode');
    
        } else {
    
            $lines = $xml->xpath('//TextLine/TextEquiv/Unicode');
        }
    
        if ($lines === false) {
    
            throw new RuntimeException("XPath query failed for file: $filePath");
        }
    
        // Trim each line in &lines.
        $textLines = array_map(static fn($line) => trim((string)$line),
                               $lines);
    
        //return implode(PHP_EOL, $textLines);
        return $textLines;
    }
    
    public function __invoke(\SplFileObject $file) : array
    {
        libxml_use_internal_errors(true);
    }
}

function main(array $argv): void
{
    if (count($argv) !== 3) {

        echo "Usage: php transkribus_export.php <input_dir> <output_dir>\n";
        exit(1);
    }

    $inputDir = realpath($argv[1]);

    $outputDir = $argv[2];

    if ($inputDir === false || !is_dir($inputDir)) {

        fwrite(STDERR, "Error: Input directory does not exist or is not readable.\n");

        exit(1);
    }

    if (!is_dir($outputDir)) {

        if (!mkdir($outputDir, 0777, true)) {

            fwrite(STDERR, "Error: Failed to create output directory: $outputDir\n");

            exit(1);
        }
    }

    try {

        processXmlDirectory($inputDir, $outputDir);

        echo "✅ Text files created in: $outputDir\n";

    } catch (Throwable $e) {

        fwrite(STDERR, 'Error: ' . $e->getMessage() . "\n");

        exit(1);
    }
}

function processXmlDirectory(string $inputDir, string $outputDir): void
{
    $files = glob($inputDir . DIRECTORY_SEPARATOR . '*.xml');

    if ($files === false) {

        throw new RuntimeException("Failed to list XML files in: $inputDir");
    }
 
    $extractor = new TextExtractor();

    foreach ($files as $filePath) {
        
        $textArray = $extractor($filePath);

        $baseName = pathinfo($filePath, PATHINFO_FILENAME);

        $outputFile = $outputDir . DIRECTORY_SEPARATOR . $baseName . '.txt';

        print_r($textArray);

        file_put_contents($outputFile, implode(PHP_EOL, $textArray));
    }
}


main($argv);

