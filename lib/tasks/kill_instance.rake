desc "Generate a heavy usage of CPU for a long period"
task :kill_instance do
  while true
    (1..10000).inject(&:*)*rand(10000)
  end
end
