
create database  ecommerce;
use ecommerce;
select * from customers;
alter table customers add primary key(customer_id);
alter table customers modify customer_id int ;
describe customers;
alter table customers modify country  varchar(20);

select * from categories;
describe categories;
alter table categories add primary key(category_id);

select * from order_items;
describe order_items;
alter table order_items add primary key(order_item_id);

select * from orders;
describe orders;
alter table orders add primary key(order_id);
alter table orders modify shipping_date date;

select * from payments;
describe payments;
alter table payments add primary key(payment_id);
alter table payments modify payment_date date;

select * from products;
describe products;
alter table products modify date_added date;

select * from shopping_cart;
describe shopping_cart;
alter table shopping_cart modify added_date date;

select * from product_images;
describe product_images;
alter table product_images add primary key(product_id);

 alter table categories drop  primary key;
-- join tables

 create table product_det as Select C.*,p.product_id,p.product_name,p.`description`,p.price,p.stock_quantity,p.date_added,p.`status`,
i.image_id,i.image_url,i.is_main_image from categories c
left join products p on c.category_id=p.category_id
left join product_images i on p.product_id=i.product_id;
select * from product_det;
drop table product_det;


 -- using join customers and cart
  create table dummy as select C.*,s.cart_id,s.product_id,s.quantity,s.added_date,i.order_item_id,i.price,i.order_id,p.payment_id,p.payment_method,p.payment_amount,p.payment_date,payment_status from customers C
 inner join shopping_cart  S on c.customer_id=s.customer_id
 inner join order_items i on s.product_id=i.product_id
 inner join payments P on i.order_id=p.order_id;
select * from dummy;
drop  table dummy;

-- secondary table
create table customer_cart(customer_id int,first_name varchar(30),last_name varchar(30),email varchar(100), phone varchar(20), address varchar(100),
  city varchar(30),state varchar(20), zip_code int, country varchar(20), registration_date date, cart_id int, product_id int , quantity int,
  added_date date,order_item_id int,order_id int auto_increment,price int,payment_id int,payment_method varchar(30),payment_amount int,payment_date date,payment_status varchar(20),primary key(order_id));
  drop table customer_cart;
  select * from customer_cart;

delimiter //
 create trigger update_orders after insert on customer_cart for each row
 begin
 update product_det
 set stock_quantity = stock_quantity - new.quantity
 where product_id=new.Product_id;
 end//
 delimiter ;
 drop trigger update_orders;
 
 -- for setting price
  delimiter //
  create trigger set_price before insert on customer_cart for each row
  begin
  if new.product_id=1 then  set new.price=99.99 ,new.registration_date=curdate() , new.added_date=curdate();
  elseif new.product_id=2 then set new.price=149.99 , new.registration_date=curdate() , new.added_date=curdate();
  elseif new.product_id=3 then set new.price=29.99 , new.registration_date=curdate() , new.added_date=curdate();
  elseif new.product_id=4 then set new.price=199.99 , new.registration_date=curdate() , new.added_date=curdate();
  else set new.price=0;
  end if;
 end //
  delimiter ;
  drop trigger  set_price;
  
  
  -- updating 
 create table orders_table(order_item_id int,order_id int,product_id int,quantity int,price int,total int,primary key(order_id));
 drop table orders_table;
 
 delimiter //
 create trigger tot_count after insert on customer_cart for each row
 begin
 insert into orders_table(order_item_id,order_id,product_id ,quantity ,price ,total)
 values(new.order_item_id,new.order_id,new.product_id,new.quantity,new.price,quantity*price);
 end //
 delimiter ;
 drop trigger tot_count;
 
  
 

-- secondary table
create  table payment_check( payment_id int auto_increment,order_id int,payment_method varchar(20), payment_amount int, payment_date date, payment_status varchar(20),price int,quantity int,product_id int,primary key(payment_id));
drop table payment_check;


delimiter //
create trigger pay_check after insert  on customer_cart for each row
begin
if  new.price>=300 then insert into payment_check(order_id,payment_method,payment_amount,payment_date,payment_status,price,quantity,product_id)
values(new.order_id,'Card',(new.price*new.quantity)+100,curdate(),'completed',new.price,new.quantity,new.product_id);
elseif new.price>=200 then insert into payment_check(order_id,payment_method,payment_amount,payment_date,payment_status,price,quantity,product_id)
values(new.order_id,'phonepe/Gpay',(new.price*new.quantity)+100,curdate(),'completed',new.price,new.quantity,new.product_id);
else insert into payment_check(order_id,payment_method,payment_amount,payment_date,payment_status,price,quantity,product_id)
values(new.order_id,'COD',(new.price*new.quantity)+100,curdate(),'Pending',new.price,new.quantity,new.product_id);
end if;
end //
delimiter ;
drop trigger pay_check;


 
 -- updating values in customer_cart 
 delimiter //
create trigger update_cart after update on customer_cart for each row
begin

 update product_det
 set stock_quantity = stock_quantity - new.quantity
 where product_id=new.Product_id;  
 
update orders_table
set total = new.quantity*price,
quantity =new.quantity
 where product_id = new.product_id;

update payment_check
set payment_amount=(new.quantity * price)+100,
quantity = new.Quantity
where product_id=new.product_id;

IF (NEW.quantity*new.price)+ 100 >= 800 THEN
        UPDATE payment_check
        SET payment_method = 'card',
            payment_status = 'completed'
        WHERE product_id = NEW.product_id;
    ELSEIF (NEW.quantity*new.price)+100 >= 550 THEN
        UPDATE payment_check
        SET payment_method = 'phonepe/Gpay',
            payment_status = 'completed'
        WHERE product_id = NEW.product_id;
    ELSE
        UPDATE payment_check
        SET payment_method = 'COD',
            payment_status = 'Pending'
        WHERE order_id = NEW.order_id;
end if;
 end//
delimiter ;
drop  trigger update_cart;

 
 -- dismis the completed order
 -- secondary table
create table complete_order(payment_id int,order_id int,payment_method varchar(30),payment_amount int,payment_date date,payment_status varchar(20));
drop table complete_order;

-- setting trigger for delete

delimiter //
create trigger delete_complete after delete on payment_check for each row
begin
insert into
complete_order(payment_id,order_id,payment_method,payment_amount,payment_date,payment_status)
values(old.payment_id,old.order_id,old.payment_method,old.payment_amount,old.payment_Date,old.payment_status);
end //
delimiter ;
drop trigger  delete_complete;

-- LOGS TABLE
CREATE TABLE Logs(message varchar(100),product_id int,cart_id int,order_id int, time_date timestamp);
drop table `logs`;

-- setting stock message before inserting customer_cart
delimiter //
CREATE TRIGGER check_stock
BEFORE INSERT ON customer_cart
FOR EACH ROW
BEGIN
    DECLARE current_stock INT;
    SELECT stock_quantity INTO current_stock FROM product_det WHERE product_id = NEW.product_id;
    
    IF current_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Insufficient stock for this item.';
        else
 INSERT INTO LOGS(message,product_id,cart_id,order_id,time_date)
 VALUES('Item added to your cart',new.product_id,new.order_id,new.cart_id,NOW());
    END IF;
END //
delimiter ;
drop trigger check_stock;

-- setting stock messafe before updating customer_cart
delimiter //
create trigger stock_update
 after update on customer_cart
 FOR EACH ROW
 BEGIN
 DECLARE current_stock INT;
 SELECT stock_quantity into current_stock from product_det where PRoduct_id=new.product_id;
 
 IF Current_stock < NEW.Quantity then
 SIGNAL SQLSTATE '45000'
 SET MESSAGE_TEXT='Insufficient stock for this item';
 else
INSERT INTO logs(message,product_id,cart_id,order_id,time_date)
VALUES('Your Cart Updated',new.product_id,new.order_id,new.cart_id,NOW());
 END IF;
 END //
 DELIMITER ;
 drop trigger stock_update;
 
 
  -- inserting vlues
  insert into customer_cart(customer_id,first_name,last_name,email,phone, address,city,state,zip_code,country,cart_id,product_id,
  quantity,order_item_id,payment_id,payment_method,Payment_amount,Payment_status)
  select customer_id,first_name,last_name,email,phone, address,city,state,zip_code, country,cart_id,product_id,quantity,order_item_id,payment_id,payment_method,
  Payment_amount,Payment_status  from dummy;
 select * from customer_cart;
  select * from product_det;

 insert into customer_cart(customer_id,first_name,last_name,email,phone,address,city,state,zip_code,country,cart_id,product_id,quantity,order_item_id)
  values(6,'Manish','pandya','Manish.pandya@gmail.com','666-4455','321 Bandra','Kolkata','KA',51009,'INDIA',7,4,5,5);

delete from payment_check where payment_status='completed';
update customer_cart set quantity=4 where order_id=2;
update payment_check set payment_status ='completed' where order_id=1;



select * from orders_table;
 select * from customer_cart;
 select * from dummy;
 select * from payment_check;
 select * from product_det;
select * from complete_order;
select * from logs;

