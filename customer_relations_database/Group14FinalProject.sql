SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema CustomerRewards
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Schema CustomerRewards
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `CustomerRewards` DEFAULT CHARACTER SET utf8 ;
USE `Group14FinalProject` ;

-- -----------------------------------------------------
-- Table `CustomerRewards`.`Company`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Company` (
  `idCompany` INT NOT NULL,
  `Name` VARCHAR(45) NOT NULL,
  `Address` VARCHAR(45) NOT NULL,
  `City` VARCHAR(45) NOT NULL,
  `State` VARCHAR(45) NOT NULL,
  `ZipCode` INT NOT NULL,
  `PhoneNumber` INT NOT NULL,
  `Contact` VARCHAR(45) NOT NULL,
  `Locations` INT NOT NULL,
  PRIMARY KEY (`idCompany`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Employees`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Employees` (
  `idCompany` INT NOT NULL,
  `SSN` INT NOT NULL,
  `FirstName` VARCHAR(45) NOT NULL,
  `LastName` VARCHAR(45) NOT NULL,
  `Address` VARCHAR(45) NOT NULL,
  `City` VARCHAR(45) NOT NULL,
  `State` VARCHAR(45) NOT NULL,
  `ZipCode` INT NOT NULL,
  `Sex` VARCHAR(45) NOT NULL,
  `Birthdate` DATETIME NOT NULL,
  PRIMARY KEY (`idCompany`, `SSN`),
  CONSTRAINT `fk_Employees_Company1`
    FOREIGN KEY (`idCompany`)
    REFERENCES `CustomerRewards`.`Company` (`idCompany`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Customers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Customers` (
  `idCompany` INT NOT NULL,
  `idCustomers` INT NOT NULL,
  `FirstName` VARCHAR(45) NOT NULL,
  `LastName` VARCHAR(45) NOT NULL,
  `PhoneNumber` INT NULL,
  `Email` VARCHAR(45) NULL,
  `Birthdate` DATETIME NULL,
  PRIMARY KEY (`idCustomers`, `idCompany`),
  CONSTRAINT `fk_Customers_Company1`
    FOREIGN KEY (`idCompany`)
    REFERENCES `CustomerRewards`.`Company` (`idCompany`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Products`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Products` (
  `idCompany` INT NOT NULL,
  `idProducts` INT NOT NULL,
  `Name` VARCHAR(45) NOT NULL,
  `Price` VARCHAR(45) NOT NULL,
  `Quantity` INT NOT NULL,
  PRIMARY KEY (`idProducts`, `idCompany`),
  CONSTRAINT `fk_Products_Company1`
    FOREIGN KEY (`idCompany`)
    REFERENCES `CustomerRewards`.`Company` (`idCompany`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`RewardsCatalog`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`RewardsCatalog` (
  `idCompany` INT NOT NULL,
  `idRewardsCatalog` INT NOT NULL,
  `Name` VARCHAR(45) NOT NULL,
  `StartDate` DATETIME NOT NULL,
  `EndDate` DATETIME NOT NULL,
  `Points` INT NOT NULL,
  PRIMARY KEY (`idRewardsCatalog`),
  CONSTRAINT `fk_Rewards_Company1`
    FOREIGN KEY (`idCompany`)
    REFERENCES `CustomerRewards`.`Company` (`idCompany`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Surveys`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Surveys` (
  `idCompany` INT NOT NULL,
  `idSurveys` INT NOT NULL,
  `Name` VARCHAR(45) NOT NULL,
  `StartDate` DATETIME NOT NULL,
  `EndDate` DATETIME NOT NULL,
  PRIMARY KEY (`idSurveys`),
  CONSTRAINT `fk_Surveys_Company1`
    FOREIGN KEY (`idCompany`)
    REFERENCES `CustomerRewards`.`Company` (`idCompany`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Campaigns`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Campaigns` (
  `idCompany` INT NOT NULL,
  `idCampaigns` INT NOT NULL,
  `Name` VARCHAR(45) NOT NULL,
  `StartDate` DATETIME NOT NULL,
  `EndDate` DATETIME NOT NULL,
  PRIMARY KEY (`idCampaigns`),
  CONSTRAINT `fk_Campaigns_Company1`
    FOREIGN KEY (`idCompany`)
    REFERENCES `CustomerRewards`.`Company` (`idCompany`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Sales`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Sales` (
  `idCompany` INT NOT NULL,
  `idSales` INT NOT NULL,
  `idCustomer` INT NOT NULL,
  `idProducts` INT NOT NULL,
  `Price` VARCHAR(45) NOT NULL,
  `Quantity` INT NOT NULL,
  PRIMARY KEY (`idSales`, `idProducts`, `idCustomer`),
  CONSTRAINT `fk_Sales_Products1`
    FOREIGN KEY (`idProducts`)
    REFERENCES `Group14FinalProject`.`Products` (`idProducts`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Sales_Customers1`
    FOREIGN KEY (`idCustomer`)
    REFERENCES `CustomerRewards`.`Customers` (`idCustomers`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Points`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Points` (
  `idCustomer` INT NOT NULL,
  `idSales` INT NOT NULL,
  `Points` INT NOT NULL,
  PRIMARY KEY (`idSales`),
  CONSTRAINT `fk_Points_Sales1`
    FOREIGN KEY (`idSales`)
    REFERENCES `CustomerRewards`.`Sales` (`idSales`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Rewards`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Rewards` (
  `idRewardsCatalog` INT NOT NULL,
  `idCustomers` INT NOT NULL,
  `idCompany` VARCHAR(45) NOT NULL,
  CONSTRAINT `fk_Rewards_RewardsCatalog1`
    FOREIGN KEY (`idRewardsCatalog`)
    REFERENCES `Group14FinalProject`.`RewardsCatalog` (`idRewardsCatalog`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Rewards_Customers1`
    FOREIGN KEY (`idCustomers`)
    REFERENCES `CustomerRewards`.`Customers` (`idCustomers`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Campaigns_has_Customers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Campaigns_has_Customers` (
  `idCampaigns` INT NOT NULL,
  `idCustomers` INT NOT NULL,
  `idCompany` INT NOT NULL,
  CONSTRAINT `fk_Campaigns_has_Customers_Campaigns1`
    FOREIGN KEY (`idCampaigns`)
    REFERENCES `Group14FinalProject`.`Campaigns` (`idCampaigns`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Campaigns_has_Customers_Customers1`
    FOREIGN KEY (`idCustomers`)
    REFERENCES `CustomerRewards`.`Customers` (`idCustomers`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Surveys_has_Customers`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Surveys_has_Customers` (
  `idSurveys` INT NOT NULL,
  `idCustomers` INT NOT NULL,
  `idCompany` INT NOT NULL,
  CONSTRAINT `fk_Surveys_has_Customers_Surveys1`
    FOREIGN KEY (`idSurveys`)
    REFERENCES `Group14FinalProject`.`Surveys` (`idSurveys`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Surveys_has_Customers_Customers1`
    FOREIGN KEY (`idCustomers`)
    REFERENCES `CustomerRewards`.`Customers` (`idCustomers`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `CustomerRewards`.`Manager`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Manager` (
  `idCompany` INT NOT NULL,
  `mgr_ssn` INT NOT NULL,
  PRIMARY KEY (`idCompany`, `mgr_ssn`),
  CONSTRAINT `fk_Manager_Employees1`
    FOREIGN KEY (`idCompany` , `mgr_ssn`)
    REFERENCES `CustomerRewards`.`Employees` (`idCompany` , `SSN`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `GCustomerRewards`.`Contact`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `CustomerRewards`.`Contact` (
  `idCompany` INT NOT NULL,
  `contact_ssn` INT NOT NULL,
  PRIMARY KEY (`idCompany`, `contact_ssn`),
  CONSTRAINT `fk_Contact_Employees1`
    FOREIGN KEY (`idCompany` , `contact_ssn`)
    REFERENCES `CustomerRewards`.`Employees` (`idCompany` , `SSN`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
