-- CREATE THE DATABASE

CREATE DATABASE nashville_housing;

-- CREATE THE TABLE
DROP TABLE IF EXISTS PropertyRecords;
CREATE TABLE PropertyRecords (
    UniqueID INT AUTO_INCREMENT PRIMARY KEY,
    ParcelID VARCHAR(50),
    LandUse VARCHAR(100),
    PropertyAddress VARCHAR(255),
    SaleDate DATE,
    SalePrice DECIMAL(12,2),
    LegalReference VARCHAR(255),
    SoldAsVacant VARCHAR(10),
    OwnerName VARCHAR(255),
    OwnerAddress VARCHAR(255),
    Acreage DECIMAL(10,2),
    TaxDistrict VARCHAR(100),
    LandValue DECIMAL(12,2),
    BuildingValue DECIMAL(12,2),
    TotalValue DECIMAL(12,2),
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);

-- IMPORT the data to the table

SET GLOBAL local_infile = 1;


LOAD DATA LOCAL INFILE '/Users/andre/Downloads/1data_analist/portfolio/project3/Nashville_Housing_Data_Cleaning.csv'
INTO TABLE PropertyRecords
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- CLEANING DATA

Select *
From nashville_housing.PropertyRecords;

-- ------------------------------------------------------------------------------------------------------------------------


-- Standardize Date Format


Select saleDateConverted, CONVERT(Date,SaleDate)
From nashville_housing.PropertyRecords


Update PropertyRecords
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE PropertyRecords
Add SaleDateConverted Date;

Update PropertyRecords
SET SaleDateConverted = CONVERT(Date,SaleDate)


 -- ------------------------------------------------------------------------------------------------------------------------
 
 
-- Populate Property Address data

Select *
From nashville_housing.PropertyRecords
Where PropertyAddress =''
-- order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, CASE 
        WHEN a.PropertyAddress IS NULL OR a.PropertyAddress = '' THEN b.PropertyAddress
    END AS address
From nashville_housing.PropertyRecords a
JOIN nashville_housing.PropertyRecords b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress =''


SET SQL_SAFE_UPDATES = 0;

UPDATE nashville_housing.PropertyRecords a
JOIN nashville_housing.PropertyRecords b
  ON a.ParcelID = b.ParcelID
  AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress = '' OR a.PropertyAddress IS NULL;


-- ------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From nashville_housing.PropertyRecords
-- Where PropertyAddress =''
-- order by ParcelID

SELECT
  SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address1,
  SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, CHAR_LENGTH(PropertyAddress)) AS Address2
FROM nashville_housing.PropertyRecords;

ALTER TABLE PropertyRecords
Add PropertySplitAddress Nvarchar(255);

Update PropertyRecords
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1)

ALTER TABLE PropertyRecords
Add PropertySplitCity Nvarchar(255);

Update PropertyRecords
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, CHAR_LENGTH(PropertyAddress))

SELECT * FROM nashville_housing.PropertyRecords;



Select OwnerAddress
From nashville_housing.PropertyRecords


SELECT
  TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1)) AS Part3,
  TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)) AS Part2,
  TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)) AS Part1
FROM nashville_housing.PropertyRecords;



ALTER TABLE nashville_housing.PropertyRecords
Add OwnerSplitAddress Nvarchar(255);

Update nashville_housing.PropertyRecords
SET OwnerSplitAddress = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1))


ALTER TABLE nashville_housing.PropertyRecords
Add OwnerSplitCity Nvarchar(255);

Update nashville_housing.PropertyRecords
SET OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1))



ALTER TABLE nashville_housing.PropertyRecords
Add OwnerSplitState Nvarchar(255);

Update nashville_housing.PropertyRecords
SET OwnerSplitState =   TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1))



Select *
From nashville_housing.PropertyRecords




--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From nashville_housing.PropertyRecords
Group by SoldAsVacant
order by 2




Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From nashville_housing.PropertyRecords

SET SQL_SAFE_UPDATES = 0;

Update PropertyRecords
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates


       
 
       
       WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From nashville_housing.PropertyRecords
-- order by ParcelID
)
SELECT *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress;


DELETE FROM nashville_housing.PropertyRecords
WHERE UniqueID IN (
    SELECT UniqueID FROM (
        SELECT UniqueID,
               ROW_NUMBER() OVER (
                   PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
                   ORDER BY UniqueID
               ) AS row_num
        FROM nashville_housing.PropertyRecords
    ) AS t
    WHERE t.row_num > 1
);


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



Select *
From nashville_housing.PropertyRecords


ALTER TABLE nashville_housing.PropertyRecords
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;












