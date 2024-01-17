/* Data Cleaning in SQL Queries 

I transformed raw Housing data in SQL to make it usable for analysis.

Skills Used: Substrings, Alter, Update, Removed Duplicates, Deleted Unused Columns and Replaced Values
*/

SELECT *
FROM [NashvilleHousing] 



-- Populate Property Address data 

SELECT *
FROM [NashvilleHousing] 
-- WHERE PropertyAddress is NULL 
ORDER BY ParcelID


/*SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM [NashvilleHousing] AS a
JOIN [NashvilleHousing] AS b
    ON a.ParcelID = b.ParcelID 
    AND a.[UniqueID] <> b.[UniqueID] 
WHERE a.PropertyAddress is NULL*/


UPDATE [NashvilleHousing]
SET PropertyAddress = (
    SELECT IFNULL(b.PropertyAddress, [NashvilleHousing].PropertyAddress)
    FROM [NashvilleHousing] AS b
    WHERE [NashvilleHousing].ParcelID = b.ParcelID 
    AND [NashvilleHousing].UniqueID <> b.UniqueID
)
WHERE EXISTS (
    SELECT 1
    FROM [NashvilleHousing] AS b
    WHERE [NashvilleHousing].ParcelID = b.ParcelID 
    AND [NashvilleHousing].UniqueID <> b.UniqueID
);



-- Breaking out the Address into Individual Columns (Address, City, State) 

SELECT PropertyAddress
FROM [NashvilleHousing] 


SELECT 
SUBSTR(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1) AS Address,
SUBSTR(PropertyAddress, INSTR(PropertyAddress, ',') + 1, LENGTH(PropertyAddress)) AS Address
FROM [NashvilleHousing]  


ALTER TABLE [NashvilleHousing]
ADD COLUMN PropertySplitAddress TEXT;

UPDATE [NashvilleHousing]
SET PropertySplitAddress = SUBSTR(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1);

ALTER TABLE [NashvilleHousing]
ADD COLUMN PropertySplitCity TEXT;

UPDATE [NashvilleHousing]
SET PropertySplitCity = SUBSTR(PropertyAddress, INSTR(PropertyAddress, ',') + 1, LENGTH(PropertyAddress));



SELECT OwnerAddress
FROM [NashvilleHousing]

SELECT
    SUBSTR(OwnerAddress, 1, INSTR(OwnerAddress || ',', ',') - 1) AS Part1,
    SUBSTR(OwnerAddress, INSTR(OwnerAddress || ',', ',') + 1, INSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress || ',', ',') + 1) || ',', ',') - 1) AS Part2,
    SUBSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress || ',', ',') + 1), INSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress || ',', ',') + 1) || ',', ',') + 1) AS Part3
FROM [NashvilleHousing]


ALTER TABLE [NashvilleHousing]
ADD COLUMN OwnerSplitAddress TEXT;

UPDATE [NashvilleHousing]
SET OwnerSplitAddress = SUBSTR(OwnerAddress, 1, INSTR(OwnerAddress || ',', ',') - 1);

ALTER TABLE [NashvilleHousing]
ADD COLUMN OwnerSplitCity TEXT;

UPDATE [NashvilleHousing]
SET OwnerSplitCity = SUBSTR(OwnerAddress, INSTR(OwnerAddress || ',', ',') + 1, INSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress || ',', ',') + 1) || ',', ',') - 1);

ALTER TABLE [NashvilleHousing]
ADD COLUMN OwnerSplitState TEXT;

UPDATE [NashvilleHousing]
SET OwnerSplitState = SUBSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress || ',', ',') + 1), INSTR(SUBSTR(OwnerAddress, INSTR(OwnerAddress || ',', ',') + 1) || ',', ',') + 1);



-- Change Y and N to Yes and No in "SoldAsVacant" Column 

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM [NashvilleHousing]
Group by SoldAsVacant
Order by 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' Then 'Yes'
    WHEN SoldAsVacant = 'N' Then 'No'
    Else SoldAsVacant 
    END 
FROM [NashvilleHousing]


UPDATE [NashvilleHousing]
SET SoldAsVacant = (
    CASE WHEN SoldAsVacant = 'Y' Then 'Yes'
    WHEN SoldAsVacant = 'N' Then 'No'
    Else SoldAsVacant 
    END 
)
 


-- Remove Duplicates 

DELETE 
FROM [NashvilleHousing]
WHERE UniqueID NOT IN (
    SELECT UniqueID
    FROM [NashvilleHousing]
    WHERE ROWID IN (
        SELECT ROWID
        FROM (
            SELECT ROWID,
                   ROW_NUMBER() OVER (
                       PARTITION BY ParcelID, 
                           PropertyAddress, 
                           SalePrice, 
                           SaleDate, 
                           LegalReference
                       ORDER BY UniqueID
                   ) AS RowNum
            FROM [NashvilleHousing]
        )
        WHERE RowNum = 1
    )
);



-- Delete Unused Columns 

SELECT * 
FROM [NashvilleHousing]

CREATE TABLE [NashvilleHousing_New] AS
SELECT UniqueID,
ParcelID,
LandUse,
SaleDate,
SalePrice,
LegalReference,
SoldAsVacant,
OwnerName,
Acreage,
LandValue,
BuildingValue,
TotalValue,
YearBuilt,
Bedrooms,
FullBath,
HalfBath,
PropertySplitAddress,
PropertySplitCity,
OwnerSplitAddress,
OwnerSplitCity,
OwnerSplitState
FROM [NashvilleHousing]

INSERT INTO [NashvilleHousing_New] (UniqueID,
ParcelID,
LandUse,
SaleDate,
SalePrice,
LegalReference,
SoldAsVacant,
OwnerName,
Acreage,
LandValue,
BuildingValue,
TotalValue,
YearBuilt,
Bedrooms,
FullBath,
HalfBath,
PropertySplitAddress,
PropertySplitCity,
OwnerSplitAddress,
OwnerSplitCity,
OwnerSplitState) 
SELECT DISTINCT UniqueID,
ParcelID,
LandUse,
SaleDate,
SalePrice,
LegalReference,
SoldAsVacant,
OwnerName,
Acreage,
LandValue,
BuildingValue,
TotalValue,
YearBuilt,
Bedrooms,
FullBath,
HalfBath,
PropertySplitAddress,
PropertySplitCity,
OwnerSplitAddress,
OwnerSplitCity,
OwnerSplitState
FROM [NashvilleHousing]

DROP TABLE [NashvilleHousing]

ALTER TABLE [NashvilleHousing_New] RENAME TO [NashvilleHousing]

SELECT * 
FROM [NashvilleHousing]

