create database if not exists archion;

use archion;

create table if not exists images (
    id int not null auto_increment primary key,
    image_num int not null,
    lpage_num int not null,
    permalink varchar(60) not null,
    register_id int not null,
    ymlfile varchar(45) not null,
    unique (register_id, image_num),
    unique (permalink),
    unique (ymlfile),
    foreign key(register_id) references registers(id)
) engine = INNODB;


create table if not exists events ( 
   id int not null auto_increment primary key,
   event ENUM(
        'birth',
        'baptism',
        'confirmation',
        'marriage',
        'death',
        'funeral'
   ) NOT NULL,
   view_date date not null,
   date DATE NOT NULL,
   entry_num int not null,
   place_id int not null,
   image_id int not null,
   foreign key(image_id) references images(id),
   foreign key(place_id) references place_names(id)
) engine = INNODB;

-- If `gender` is not clear from the name, use `unknown`.
create table if not exists event_persons (
  id int not null auto_increment primary key,
  given varchar(45) not null,
  surname varchar(25) not null,
  gender enum('male', 'female', 'unknown'),
  event_id int not null,
  fulltext (given, surname),
  foreign key(event_id) references events(id)
) engine = INNODB;

create table if not exists person_facts (
   id int not null auto_increment primary key,
   type enum(
     'job',
     'baptism',
     'birth',
     'approx_birth_year',
     'child--_birth_order',
     'sex_birth_order',
     'residence',
     'marriage',
     'proclaimed',
     'death',
     'deceased',
     'death_cause',
     'gender',
     'burial',
     'confirmation',
     'funeral',
     'illegitimate',  
     'legitimate',
     'married',
     'widow',
     'widower',
     'virgin',
     'remark'
   ) not null,
   person_id int not null, 
   event_id int not null,
   date_type enum('unknown', 'approx_year', 'known'),
   date date not null,
   place_id int not null, 
   unique (person_id, event_id, type),
   foreign key(person_id) references event_persons(id),
   foreign key(event_id)  references events(id),
   foreign key(place_id)  references place_names(id)
) engine = INNODB;

-- Relationship facts
create table if not exists relationships (
   id int not null auto_increment primary key,
   type enum('husband_wife', 'godparent_infant',
             'parent_child', 'unmarried_couple') not null,
   person1 int not null,
   person2 int not null,
   event_id int null,
   unique(person1, person2, type),
   foreign key(person1) references event_persons(id),
   foreign key(person2) references event_persons(id),
   foreign key(event_id) references events(id)
) engine = INNODB;

create table if not exists facts_details (
 fact_id int not null primary key,
 details varchar(65) not null,
 foreign key(fact_id) references person_facts(id) 
) engine = INNODB;

create or replace view all_couples as
select 
   concat_ws(men.given, ' ', men.surname) as male_partner,
   men.id        as male_partner_id,
   concat_ws(women.given, ' ', women.surname) as female_partner,
   women.id      as female_partner_id,
   r.id          as relationship_id,
   r.type        as type_of_relationship,
   r.person2     as person2,
   events.date   as event_date,
   events.event  as event_type,
   events.id     as event_id
 from 
    event_persons as men
 join
    relationships as r
      on r.person1=men.id and men.gender='male'
      and (r.type='parent_child' or r.type='husband_wife')
  join
    event_persons as women
      on (women.id=r.person2 and
         women.gender='female' and r.type='husband_wife')
      or (women.id=r.person1 and
          women.gender='female' and r.type='parent_child')
  join 
    events on events.id=r.event_id;

create or replace view all_couples as
select 
   concat_ws(men.given, ' ', men.surname) as male_partner,
   men.id        as male_partner_id,
   concat_ws(women.given, ' ', women.surname) as female_partner,
   women.id      as female_partner_id,
   r.id          as relationship_id,
   r.type        as type_of_relationship,
   r.person2     as person2,
   events.date   as event_date,
   events.event  as event_type,
   events.id     as event_id
 from 
    event_persons as men
 join
    relationships as r
      on r.person1=men.id and men.gender='male'
      and (r.type='couple' or r.type='husband_wife')
 join
    event_persons as women
      on (women.id=r.person2 and
         women.gender='female' and r.type='husband_wife')
      or (women.id=r.person1 and
          women.gender='female' and r.type='couple')
 join 
   events on events.id=r.event_id;

create or replace view all_couples2 as
(select
   men.given       as male_given,
   men.surname     as male_surname,
   men.id          as male_id,
   females.given   as female_given,
   females.surname as female_surname,
   females.id      as female_id,
   rf.type         as type_of_relationship,
   rf.person2      as person2,
   events.date  as event_date,
   events.event as event_type
 from
    event_persons as men
 join
    relationships as rf
      on rf.person1=men.id and men.gender='male'
  join
    event_persons as females
      on females.id=rf.person2
  join
    events
      on events.id=rf.event_id
where rf.type='husband_wife')
union
(
select
   men.given         as male_given,
   men.surname       as male_surname,
   men.id            as male_id,
   females.given     as female_given,
   females.surname   as female_surname,
   females.id        as female_id,
   rf.type           as relationship_type,
   rf.person2        as person2,
   events.date  as event_date,
   events.event as event_type
 from
    event_persons as men
 join
    relationships as rf
      on rf.person1=men.id and men.gender='male'
  join
    event_persons as females
      on females.id=rf.person2 and females.gender='female'
  join
    events
      on events.id=rf.event_id
where rf.type='parent_child');

create or replace view all_couples_maybe_children as
select
     male_partner,
     male_partner_id,
     female_partner,
     female_partner_id,
     all_couples.relationship_id,
     type_of_relationship,
     person2,
     concat_ws(children.given, ' ', children.surname) as child, 
     children.id as child_id
  from
     all_couples
  left join
     event_persons as children
       on person2=children.id and type_of_relationship='parent_child';

create or replace view parents_with_children as
select 
  fathers.given   as fathers_given,
  fathers.surname as fathers_surname,
  fathers.id      as fathers_id,
  mothers.given   as mothers_given,
  mothers.surname as mothers_surname,
  mothers.id      as mothers_id,
  kids.given      as child_given,
  kids.surname    as child_surname,
  kids.id         as child_id
 from 
    event_persons as kids
 join
    relationships as r
      on r.person2=kids.id
  join 
    event_persons as fathers
      on fathers.id=r.person1 and fathers.gender='male'
  join
    event_persons as mothers
      on mothers.id=r.person1 and mothers.gender='female'
  where r.type='parent_child';


create or replace view detailed_facts as
select concat_ws(ep.given, ' ', ep.surname) as name,
   d.details as details
 from 
   event_persons as ep
 join 
   person_facts as pf
      on pf.person_id=ep.id
 left join
   facts_details as d
     on d.fact_id=pf.id;

create or replace view godparents as
select 
     godparent.given   as godparent_given,
     godparent.surname as godparent_surname,
     infants.given      as infants_given,
     infants.surname    as infants_surname,
     infants.id         as infants_id,
     godparent.id      as godparent_id,  
     rf.id              as rf_id
  from
     event_persons as godparent
  inner join relationships as rf
     on rf.person1=godparent.id
  inner join event_persons as infants 
     on rf.person2=infants.id;

