/*

Cleaning Data in SQL Queries - Nyia Thao

*/


Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format

--Check 
Select saleDate
From PortfolioProject.dbo.NashvilleHousing

--Test
Select saleDate, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

--Convert date column by updating table
Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)
--56477

--Add new column called SaleDateConverted
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

--Check
Select SaleDateConverted
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data

--
Select *
From PortfolioProject.dbo.NashvilleHousing
order by ParcelID

--
Select *
From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress is null
order by ParcelID

--
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null
--29

--------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)
/*
Split Address
*/


Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as City
From PortfolioProject.dbo.NashvilleHousing

--Add new column called PropertySplitAddress
ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

--Add split address to PropertySplitAddress column
Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

--Add new column called PropertySplitCity
ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

--Add split city to PropertySplitCity column
Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

/*
Split Owner Address
*/

Select *
From PortfolioProject.dbo.NashvilleHousing

Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

--Check
Select PARSENAME(OwnerAddress,1)
from PortfolioProject.dbo.NashvilleHousing

Select 
PARSENAME(REPLACE(OwnerAddress,',','.'), 3)
, PARSENAME(REPLACE(OwnerAddress,',','.'), 2)
, PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
from PortfolioProject.dbo.NashvilleHousing

--Owner Split Address
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

--Owner Split City
ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

--Owner Split State
ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant) as Cnt
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

Select SoldAsVacant
,	CASE 
		When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
From PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = 
	CASE 
		When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates 

select *
from PortfolioProject..NashvilleHousing

--Find Duplicates
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				ORDER BY UniqueID) row_num
From PortfolioProject.dbo.NashvilleHousing
order by ParcelID

	--Sanity
	Select *
	from PortfolioProject.dbo.NashvilleHousing
	where parcelID = '091 07 0 389.00'

	select a.*
	From PortfolioProject.dbo.NashvilleHousing a
		JOIN PortfolioProject.dbo.NashvilleHousing b
			on a.ParcelID = b.ParcelID
			AND a.[UniqueID] <> b.[UniqueID]
			and a.PropertyAddress = b.PropertyAddress
			and a.LegalReference = b.LegalReference
	where a.ParcelID in (select ParcelID from PortfolioProject..NashvilleHousing group by ParcelID having count(parcelID) > 1)
	and a.SaleDate = b.SaleDate and a.SalePrice = b.SalePrice
	order by a.ParcelID, UniqueID
	--091 07 0 389.00

	--Count of duplicates
	select a.ParcelID, count(*) as CNT
	From PortfolioProject.dbo.NashvilleHousing a
		JOIN PortfolioProject.dbo.NashvilleHousing b
			on a.ParcelID = b.ParcelID
			AND a.[UniqueID] <> b.[UniqueID]
			and a.PropertyAddress = b.PropertyAddress
			and a.LegalReference = b.LegalReference
	where a.ParcelID in (select ParcelID from PortfolioProject..NashvilleHousing group by ParcelID having count(parcelID) > 1)
	and a.SaleDate = b.SaleDate and a.SalePrice = b.SalePrice
	group by a.ParcelID
	order by a.ParcelID 
	--103 unique properties

--Use CTE to find Duplicates
WITH RowNumCTE AS (
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID) row_num
From PortfolioProject.dbo.NashvilleHousing
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress
--Order by ParcelID

--Delete Duplicates
WITH RowNumCTE AS (
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
	ORDER BY UniqueID) row_num
From PortfolioProject.dbo.NashvilleHousing
)
Delete
From RowNumCTE
Where row_num > 1
--104 rows deleted

---------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

Select *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
---- Importing Data using OPENROWSET and BULK INSERT	

----  More advanced and looks cooler, but have to configure server appropriately to do correctly
----  Wanted to provide this in case you wanted to try it

--GO
--sp_configure 'show advanced options', 1;
--RECONFIGURE;

--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;

--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 

------------------------------------------------------------------------------------------------------
--SP_CONFIGURE 'show advanced options', 1; 
--RECONFIGURE; 
--GO 

--SP_CONFIGURE 'Ad Hoc Distributed Queries', 1; 
--RECONFIGURE;
--GO 
 
--USE PortfolioProject 

--GO 
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 
--GO
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 
--GO
--EXEC master.[sys].[sp_MSset_oledb_prop] N'Microsoft.ACE.OLEDB.12.0', N'DisallowAdHocAccess', 1
--GO
--EXEC master.[sys].[sp_MSset_oledb_prop] N'Microsoft.ACE.OLEDB.16.0', N'AllowInProcess', 1
--GO
-----------------------------------------------------------------------------------------------------------


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing2 FROM 'C:\Users\thaon\Documents\Projects\PortfolioProject\AlexTheAnalyst\Nashville Housing Data for Data Cleaning.xlsx'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing3
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\thaon\Documents\Projects\PortfolioProject\AlexTheAnalyst\Nashville Housing Data for Data Cleaning.xlsx', [Sheet1$]);
--GO

