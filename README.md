# SDN-MEC-ICN-consumer-mobility

## An open source framework to simulate mobility in a SDN-MEC-ICN architecture

### Table of Contents:
- Getting all the materials
- Setting everything up
- Using the code
- Running a test
- Additional Support

1. Getting all the materials  
The SDN-MEC-ICN framework is available at [this link](https://github.com/telematics-lab/SDN-MEC-ICN-consumer-mobility). To run the framework you also need:
	- MATLAB software, available at [this link](https://it.mathworks.com/products/matlab.html);
	- Dijkstra's Shortest Path Algorithm implementation for MATLAB, available at [this link](https://it.mathworks.com/matlabcentral/fileexchange/12850-dijkstra-s-shortest-path-algorithm).
If you wish to generate and use topologies on your own, you also need:
	- BRITE simulator, available at [this link](https://github.com/unly/brite).
	
2. Setting everything up  
Create a folder and insert the MATLAB scripts provided on Git and the Dijkstra's algorithm script. Then, create a subfolder named "voronoi_diagrams". 
Topology files are already provided in "topologies-N" folders, where N is the number of nodes considered in the BRITE topology files. 
Each folder stores 300 topologies, numbered in ascending order. 
Other topologies generated with the BRITE simulator may be used with this framework by adopting the same naming scheme.  

3. Using the code  
First, open and run the create_voronoi_diagram script. 
Enter the number of nodes considered in the BRITE topology files and the number of generated topology files.  
Second, open and run the trace_consumer_mobility script. 
Enter the number of nodes considered in the BRITE topology files, the number of consumers interested in the same contents, the number of generated topology files and the number of simulations per topology.  
Third, open and run the compute_communication_overhead script. 
Enter the number of nodes considered in the BRITE topology files and the number of consumers interested in the same contents.  

4. Running a test  
Download the material in the [GitHub repository](https://github.com/telematics-lab/SDN-MEC-ICN-consumer-mobility) and all materiales listed in "Getting all the materials" section. 
Then, create a project folder, insert the MATLAB scripts provided on Git and the Dijkstra script and create a subfolder named "map". 
Move the topology files folder (named "Output-N", where N is the number of nodes considered in the BRITE topology files) from the "Topology files examples" folder to the project folder. 
The file examples provided have either 1415 or 12732 nodes. Otherwise, install BRITE and generate the topology files (refer to the BRITE GitHub repository for further details on this step).  
Open MATLAB and run the create_voronoi_diagram script, entering either 1415 or 12732 (the number of nodes considered in the BRITE topology files) and 30 (the number of generated topology files). 
The script generates a voronoi diagram that maps each quared meter of a 10 km x 10 km area to the closest attachment point, following the provided topologies.  
Run the trace_consumer_mobility script and enter either 1415 or 12732 (according to which number was entered in the create_voronoi_diagaram script), 40 (the number of consumers interested in the same contents), 30 (according to which number was entered in the create_voronoi_diagaram script), and 10 (the number of simulations per topology). 
The script simulates the mobility of the consumer and generates the average values of the shortest path length, the number of active links and the number of stale disjoint links.  
Run the compute_communication_overhead script and enter either 1415 or 12732 (according to which number was entered in the create_voronoi_diagaram script) and 40 (the number of consumers interested in the same contents). 
The script generates graphs showing the average communication overhead on the control plane and the data plane, the average overhead reduction, and the average bandwidth savings achieved with respect to the reference pull-based approaches.  

5. Additional Support  
Please refer to this web page for additional support.

© 2020 - TELEMATICS LAB - Politecnico di Bari
