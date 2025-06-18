<?php
declare(strict_types=1);

class Baptism {

  public int $line_no ;
  public string $child ;
  public string $birth_data;
  public \DateTime $birth;
  public \DateTime $baptism;
  public string $father;
  public string $mother;
  public array $sponsors;
  public array $Nachtraege;
}
