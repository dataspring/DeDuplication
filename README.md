TABLE OF CONTENTS

[1. Methodology and Effectiveness 4](#_Toc448178836)

[2. Accuracy Measurement 6](#_Toc448178837)

[3. Implementation & Adoption 7](#_Toc448178838)

[4. Conclusion 9](#_Toc448178839)

[5. References & Consideration 9](#_Toc448178840)

**Summary**

Data blending in the Unilever’s context is basically a subset of Record
Linkage and De-Duplication problem. Given the constraints of data which
can’t be fitted into a definitive way of comparing individual fields or
use them to narrow the amount of search is a unique problem to be
solved.

Address fields are free form data which can’t leverage ‘Blocking’ which
is the reduction of the amount of data pairs through focusing on
specified agreement patterns. Whereas SKU dataset can leverage this
feature to a limited extend and Product Hierarchy utilizes a pure simple
weighted distance ensemble.

Data blending for Unilever’s problem broadly involves the following
steps:

1.  Data Preparation

2.  Basic Stochastic Distance Measurement / Blocking

3.  Unsupervised Learning

4.  Ensemble of Distance Measurements

Above process is used fully and sparingly based on each dataset
properties and blending requirements

> **Team**
>
> **Nachi Nachiappan**, a data practioner, has worked in enterprise IT
> industry for 15 years and possess diverse business domain expertise
> including exposure to retail & financial industries. Data science
> being my passion, I keep dabbling on such projects and I hope this
> proposal is worth that effort to positively make some impact on data
> blending in enterprise and public realm.

1.  <span id="_Toc448178836" class="anchor"></span>Methodology and
    Effectiveness

**Data Preparation:**

| tyut  	| ytuty 	|
|-------	|-------	|
| tyutu 	| tyutu 	|
| gfjgj 	| gfj   	|


  |---|---|
|  Address Dataset | ```All fields are already in Upper Case and no further data prep is required.
All fields are merged into one field```  |
|---|---|
| SKU Dataset  | ```Package in Internal Dataset was reduced to Plastic for ‘BOTTLE’, ‘SACHET’, ‘POUCH’
SUBGEMENT and CATEGORY were ignored
All data were lower-cased
PACKSIZE whitespaces were removed and for those not present were borrowed from ‘SIZE’ field
New DESCRP field was created from rest of the fields```  |
|---|---|
|  Product Hierarchy |  All fields are already in Upper Case and no further data prep is required. This dataset has only single field |
|---|---|
**Basic Stochastic Distance Measurement / Blocking:**

  ----------------------------------------------------------------------------------------------------------------------------------
  Address Dataset     Uses ‘Ensemble of Distance Measurements’ straightaway
  ------------------- --------------------------------------------------------------------------------------------------------------
  SKU Dataset         Uses:
                      
                      Basic Stochastic Distance Measurement with phonetic function and string compare function using ‘jarowinkler’

  Product Hierarchy   Uses ‘Ensemble of Distance Measurements’ straightaway
  ----------------------------------------------------------------------------------------------------------------------------------

**Unsupervised Learning**

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Address Dataset     None
  ------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  SKU Dataset         Uses:
                      
                      A clustering algorithm is applied to find clusters in the comparison patterns. In the case of two
                      
                      clusters (the default), the cluster further from the origin (i.e. representing higher similarity values) is interpreted as the set of links, the other as the set of non-links.
                      
                      Supported methods tried are: K-means clustering and Bagged clustering

  Product Hierarchy   None
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**Ensemble of Distance Measurements**

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Address Dataset     An ensemble of distance functions are used with different distance metrics. Unrestricted comparison patterns for all possible data pairs: n · m for linking two data sets with n and m records.
                      
                      Distance functions include the following:
                      
                      Method name -- Description
                      
                      1.  osa Optimal string aligment, (restricted Damerau-Levenshtein distance).
                      
                      2.  lv Levenshtein distance (as in R’s native adist).
                      
                      3.  dl Full Damerau-Levenshtein distance.
                      
                      4.  hamming Hamming distance (a and b must have same nr of characters).
                      
                      5.  lcs Longest common substring distance.
                      
                      6.  qgram q-gram distance.
                      
                      7.  cosine cosine distance between q-gram profiles
                      
                      8.  jaccard Jaccard distance between q-gram profiles
                      
                      9.  jw Jaro, or Jaro-Winker distance.
                      
                      10. soundex Distance based on soundex encoding
                      
                      Ensemble is performed by finding all distances m pairs for a given n^th^ pair and finding valid distances in all metrics and taking a pair that has all distances measured with a valid value and is the least among the pairs.
  ------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  SKU Dataset         

  Product Hierarchy   
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

**How does it solve the problem?**

Basic data prep, distance measurements and unsupervised learning provide
a base set upon which reduction is performed using ‘Ensemble Distance
Measurement’ to achieve the results. No supervised learning is used as
the dataset lacks huge training sample and better domain knowledge.
Whereas our strategy is a generic one and can be applied to any dataset
without prior domain knowledge but can be optimized and fine-tuned
further with more domain knowledge and also can explore supervised
training if that is possible.

**What makes the solution robust?**

  Address Dataset     Unrestricted m~x~n Single unified column matching
  ------------------- ------------------------------------------------------------------------------------
  SKU Dataset         A set of blocking to reduce and then ensemble to narrow the match and is effective
  Product Hierarchy   Unrestricted m~x~n pair Single unified column matching

Huge datasets may have an issue on m~x~n unrestricted distance
calculation but may not be heavy compute cost given the cloud compute is
very low.

**How does the solution handle various cases of mapping?**

A full-fledged solution may need to match the level of functionality as
***open source FEBRL*** application which has all permutations. Due to
time constraint mapping is performed in the code and not exposed as a
generic interface and can be co-developed if this solution/algorithm is
selected.

1.  <span id="_Toc448178837" class="anchor"><span id="_Toc219701708"
    class="anchor"></span></span>Accuracy Measurement

  Address Dataset     TBD (still working)
  ------------------- ----------------------------
  SKU Dataset         0.7 (70% Accuracy)
  Product Hierarchy   9 out of 10 (90% Accuracy)

SKU :

![](media/image1.png){width="6.470833333333333in"
height="4.127777777777778in"}

Product Hierarchy:

![](media/image2.png){width="5.716666666666667in"
height="8.479292432195976in"}

1.  <span id="_Toc448178838" class="anchor"></span>Implementation &
    Adoption

**Prototypes hosted @**

You can access the apps as here:

  ------------------------------------------------------------------------------------------------------------------------
  Dataset             URL                                           Input Files (use these files in the Shiny.R web app)
  ------------------- --------------------------------------------- ------------------------------------------------------
  Address             <https://unileve2.shinyapps.io/addr-match/>   Addr-DataSet1.txt
                                                                    
                      **(still work in progress)**                  Addr-DataSet2.txt
                                                                    
                                                                    Addr-Match.txt

  SKU                 <https://unileve2.shinyapps.io/sku-match/>    Sku-Internal-Dataset.txt
                                                                    
                                                                    Sku-ExtNielson-Dataset.txt
                                                                    
                                                                    SKU\_Match.txt

  Product Hierarchy   <https://unileve2.shinyapps.io/unl-r-app/>    Prod-lo1-lo2-ToMatch.txt
                                                                    
                                                                    Prod-match.txt
  ------------------------------------------------------------------------------------------------------------------------

**How easily the solution can be implemented?**

It is a simple yet powerful solution strategy using standard record
linkage and de-duplication concepts and distance metrics. Can be
implemented as Shiny.R app and can be deployed for enterprise use. This
prototype uses Shiny.R to demonstrate the algorithm interface and
utilizes various R packages like RecordLinkage, stringDist, BioString,
etc.

**Any risk in implementation?**

Every project and endeavor has some risk and here are the things to
consider:

1.  More data points to test the algorithm’s consistency

2.  Does data structure change a lot – need to be studied to this
    tailored algorithm

3.  Huge dataset performance to be measured

4.  Data matching ambiguity needs to have a proper user interface to
    mark proper matching and store it for future supervised or
    unsupervised algorithms.

**Experimental Frameworks Considered:**

1.  Simple Distance measurements won’t suffice

2.  Supervised were considered but training dataset is unavailable

3.  Unsupervised – Kmeans and Bclust

4.  Stochastic – epiWeights and emiWeights

5.  Combination of Distances – Simple Distance Ensemble

<!-- -->

1.  <span id="_Toc448178839" class="anchor"></span>Conclusion

For Unilever Data Blending – a simple, powerful yet uncomplicated
algorithm that used unsupervised reduction using Distance Ensemble is
proposed which gives consistent and good results.

1.  <span id="_Toc448178840" class="anchor"></span>References &
    Consideration

**Books**

Data Matching – Springer

[High Performance Record
Linkage](http://datamining.anu.edu.au/projects/linkage-links.html)
