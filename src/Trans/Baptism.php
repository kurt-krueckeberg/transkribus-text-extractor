<?php
declare(strict_types=1);

class Baptism {
  public string $text;         // Entire text of baptism record w/o later addenda

  public int $line_no ;        // Baptism record number 

  public string $child_name;   // Child's given name

  public \DateTime $birth;     // child's birth date

  public \DateTime $baptism;   // child's baptism date

  public string $father_gname; // Father's given names

  public string $father_surname;

  public string $mother_gname; // Mother's given names

  public string $mother_maiden;

  public array $sponsors;
//  public string $addendum;
}
