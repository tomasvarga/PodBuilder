require 'pod_builder/core'
require 'json'
require 'ruby-graphviz'

module PodBuilder
  module Command
    class DependencyGraph
      def self.call          
        # Configuration.check_inited

        puts "Loading Podfile".yellow

        install_update_repo = OPTIONS.fetch(:update_repos, true)
        installer, analyzer = Analyze.installer_at(PodBuilder::basepath, install_update_repo)

        all_buildable_items = Analyze.podfile_items(installer, analyzer)
        
        g = GraphViz::new(:G, :type => "digraph", :overlap => "prism", :overlap_shrink => false, :esep => 0.1, :overlap_scaling => -3)
        
        node_dependencies = Hash.new
        all_buildable_items.group_by { |t| t.root_name }.each do |root_name, items|
          node = g.add_nodes(root_name)
      
          dependencies = items.map { |t| t.dependency_names }.flatten.map { |t| t.split("/").first }.uniq
          node_dependencies[node] = dependencies
        end

        non_root_nodes = []
        
        node_dependencies.each do |node, dependencies|
          dependencies.each do |dependency|
            dep_node = node_dependencies.keys.detect { |t| t.id == dependency }
        
            unless node == dep_node
              g.add_edges(node, dep_node)
              non_root_nodes.push(dep_node)
            end
          end
        end

        root_nodes = node_dependencies.keys - non_root_nodes

        targets = installer.podfile.root_target_definitions[0].children
        targets.each do |target|
          node = g.add_nodes(target.name)
          node[:shape] = "box"

          target_deps = target.dependencies.map { |t| t.name.split("/").first }.uniq
          target_deps.each do |target_dep|            
            root_nodes.select { |t| t.id.split("/").first == target_dep }.each do |dep_node|
              g.add_edges(node, dep_node)
            end
          end
        end

        g.output( :pdf => "/tmp/a1-g.pdf" )
        
        puts "\n\n🎉 done!\n".green
        
        return true
      end      
    end
  end  
end
